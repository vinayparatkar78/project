#!/bin/bash

# Jenkins Plugins Installation Script
# This script installs all required plugins for the Horilla CI/CD pipeline

set -e

# Jenkins CLI configuration
JENKINS_URL="http://localhost:8080"
JENKINS_CLI_JAR="/tmp/jenkins-cli.jar"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

# Check if Jenkins is running
check_jenkins() {
    log "Checking if Jenkins is running..."
    if ! curl -s "$JENKINS_URL" > /dev/null; then
        error "Jenkins is not running or not accessible at $JENKINS_URL"
    fi
    log "Jenkins is running!"
}

# Download Jenkins CLI
download_cli() {
    log "Downloading Jenkins CLI..."
    curl -s "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -o "$JENKINS_CLI_JAR"
    if [[ ! -f "$JENKINS_CLI_JAR" ]]; then
        error "Failed to download Jenkins CLI"
    fi
}

# Install plugin function
install_plugin() {
    local plugin_name="$1"
    log "Installing plugin: $plugin_name"
    
    if java -jar "$JENKINS_CLI_JAR" -s "$JENKINS_URL" -auth admin:$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin "$plugin_name"; then
        log "Successfully installed: $plugin_name"
    else
        warn "Failed to install: $plugin_name"
    fi
}

# Required plugins for Horilla CI/CD pipeline
REQUIRED_PLUGINS=(
    "docker-workflow"
    "docker-plugin"
    "pipeline-stage-view"
    "pipeline-graph-analysis"
    "ssh-agent"
    "ssh-slaves"
    "slack"
    "htmlpublisher"
    "cobertura"
    "junit"
    "git"
    "github"
    "github-branch-source"
    "pipeline-github-lib"
    "workflow-aggregator"
    "blueocean"
    "build-timeout"
    "credentials-binding"
    "timestamper"
    "ws-cleanup"
    "ant"
    "gradle"
    "nodejs"
    "python"
    "postgresql-plugin"
    "email-ext"
    "mailer"
    "matrix-auth"
    "pam-auth"
    "ldap"
    "role-strategy"
    "build-user-vars-plugin"
    "environment-injector"
    "parameterized-trigger"
    "conditional-buildstep"
    "copyartifact"
    "archive-artifacts"
    "dashboard-view"
    "view-job-filters"
    "monitoring"
    "disk-usage"
    "build-monitor-plugin"
    "prometheus"
)

main() {
    log "Starting Jenkins plugins installation for Horilla CI/CD..."
    
    # Check Jenkins status
    check_jenkins
    
    # Download CLI
    download_cli
    
    # Install plugins
    log "Installing ${#REQUIRED_PLUGINS[@]} required plugins..."
    for plugin in "${REQUIRED_PLUGINS[@]}"; do
        install_plugin "$plugin"
    done
    
    # Restart Jenkins to activate plugins
    log "Restarting Jenkins to activate plugins..."
    java -jar "$JENKINS_CLI_JAR" -s "$JENKINS_URL" -auth admin:$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword) restart
    
    log "Waiting for Jenkins to restart..."
    sleep 60
    
    # Verify Jenkins is back online
    local attempts=0
    local max_attempts=30
    while ! curl -s "$JENKINS_URL" > /dev/null && [ $attempts -lt $max_attempts ]; do
        log "Waiting for Jenkins to come back online... (attempt $((attempts+1))/$max_attempts)"
        sleep 10
        ((attempts++))
    done
    
    if [ $attempts -eq $max_attempts ]; then
        error "Jenkins failed to restart properly"
    fi
    
    log "Jenkins plugins installation completed successfully!"
    log "You can now access Jenkins at: $JENKINS_URL"
    
    # Clean up
    rm -f "$JENKINS_CLI_JAR"
}

# Run main function
main
