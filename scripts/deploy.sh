#!/bin/bash

# Horilla HRMS Deployment Script
# This script handles deployment to staging and production environments

set -e  # Exit on any error

# Configuration
APP_NAME="horilla-hrms"
DOCKER_REGISTRY="${DOCKER_REGISTRY:-your-registry.com}"
BUILD_TAG="${BUILD_TAG:-latest}"
ENVIRONMENT="${1:-staging}"  # staging or production

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Validate environment
if [[ "$ENVIRONMENT" != "staging" && "$ENVIRONMENT" != "production" ]]; then
    error "Invalid environment. Use 'staging' or 'production'"
fi

log "Starting deployment to $ENVIRONMENT environment"

# Set environment-specific variables
if [[ "$ENVIRONMENT" == "production" ]]; then
    DEPLOY_PATH="/opt/horilla"
    BACKUP_PATH="/opt/horilla/backups"
    COMPOSE_FILE="docker-compose.prod.yml"
else
    DEPLOY_PATH="/opt/horilla-staging"
    BACKUP_PATH="/opt/horilla-staging/backups"
    COMPOSE_FILE="docker-compose.staging.yml"
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_PATH"

# Function to create database backup
create_backup() {
    log "Creating database backup..."
    BACKUP_FILE="$BACKUP_PATH/horilla_backup_$(date +%Y%m%d_%H%M%S).sql"
    
    if docker-compose -f "$COMPOSE_FILE" exec -T db pg_dump -U horilla horilla_main > "$BACKUP_FILE"; then
        log "Database backup created: $BACKUP_FILE"
    else
        warn "Failed to create database backup, continuing with deployment..."
    fi
}

# Function to check application health
health_check() {
    log "Performing health check..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s http://localhost:8000/health/ > /dev/null; then
            log "Health check passed!"
            return 0
        fi
        
        log "Health check attempt $attempt/$max_attempts failed, waiting..."
        sleep 10
        ((attempt++))
    done
    
    error "Health check failed after $max_attempts attempts"
}

# Function to rollback deployment
rollback() {
    warn "Rolling back deployment..."
    
    # Get the previous image tag (you might want to store this in a file)
    PREVIOUS_TAG=$(docker images --format "table {{.Repository}}:{{.Tag}}" | grep "$APP_NAME" | head -2 | tail -1 | cut -d':' -f2)
    
    if [[ -n "$PREVIOUS_TAG" ]]; then
        log "Rolling back to tag: $PREVIOUS_TAG"
        export IMAGE_TAG="$PREVIOUS_TAG"
        docker-compose -f "$COMPOSE_FILE" up -d
        
        if health_check; then
            log "Rollback successful"
        else
            error "Rollback failed - manual intervention required"
        fi
    else
        error "No previous version found for rollback"
    fi
}

# Main deployment process
main() {
    cd "$DEPLOY_PATH" || error "Failed to change to deployment directory: $DEPLOY_PATH"
    
    # Create backup for production
    if [[ "$ENVIRONMENT" == "production" ]]; then
        create_backup
    fi
    
    # Pull the latest images
    log "Pulling Docker images..."
    export IMAGE_TAG="$BUILD_TAG"
    docker-compose -f "$COMPOSE_FILE" pull
    
    # Stop the current application
    log "Stopping current application..."
    docker-compose -f "$COMPOSE_FILE" down
    
    # Start the new version
    log "Starting new version..."
    docker-compose -f "$COMPOSE_FILE" up -d
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Run database migrations
    log "Running database migrations..."
    if ! docker-compose -f "$COMPOSE_FILE" exec -T web python manage.py migrate; then
        error "Database migration failed"
    fi
    
    # Collect static files
    log "Collecting static files..."
    if ! docker-compose -f "$COMPOSE_FILE" exec -T web python manage.py collectstatic --noinput; then
        warn "Static file collection failed, but continuing..."
    fi
    
    # Perform health check
    if ! health_check; then
        error "Deployment failed health check"
    fi
    
    # Clean up old Docker images
    log "Cleaning up old Docker images..."
    docker image prune -f || warn "Failed to clean up Docker images"
    
    log "Deployment to $ENVIRONMENT completed successfully!"
    
    # Send notification (customize as needed)
    if command -v curl &> /dev/null; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"✅ Horilla deployed to $ENVIRONMENT successfully! Build: $BUILD_TAG\"}" \
            "$SLACK_WEBHOOK_URL" 2>/dev/null || true
    fi
}

# Trap errors and attempt rollback
trap 'rollback' ERR

# Run main deployment
main

log "Deployment script completed successfully!"
