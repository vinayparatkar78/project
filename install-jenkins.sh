#!/bin/bash

# Jenkins Installation Script for Ubuntu
# This script installs Jenkins with all required dependencies

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root. Run as ubuntu user with sudo privileges."
fi

log "Starting Jenkins installation..."

# Update system packages
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Java (Jenkins requirement)
log "Installing Java 11..."
sudo apt install -y openjdk-11-jdk

# Verify Java installation
java -version || error "Java installation failed"

# Add Jenkins repository
log "Adding Jenkins repository..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
    /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
    /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list
sudo apt update

# Install Jenkins
log "Installing Jenkins..."
sudo apt install -y jenkins

# Start and enable Jenkins service
log "Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker (required for pipeline)
log "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add jenkins user to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

# Install Docker Compose
log "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install additional tools
log "Installing additional tools..."
sudo apt install -y git curl wget unzip

# Install Node.js and npm
log "Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Restart Jenkins to apply group changes
log "Restarting Jenkins service..."
sudo systemctl restart jenkins

# Wait for Jenkins to start
log "Waiting for Jenkins to start..."
sleep 30

# Get Jenkins initial admin password
log "Getting Jenkins initial admin password..."
if [[ -f /var/lib/jenkins/secrets/initialAdminPassword ]]; then
    JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    log "Jenkins installation completed successfully!"
    echo ""
    echo "=================================================="
    echo "Jenkins Access Information:"
    echo "=================================================="
    echo "URL: http://$(curl -s ifconfig.me):8080"
    echo "Initial Admin Password: $JENKINS_PASSWORD"
    echo "=================================================="
    echo ""
    log "Next steps:"
    echo "1. Open Jenkins in your browser"
    echo "2. Use the initial admin password above"
    echo "3. Install suggested plugins"
    echo "4. Create your admin user"
    echo "5. Install additional plugins for Horilla pipeline"
else
    warn "Could not find Jenkins initial admin password file"
fi

# Check service status
log "Checking Jenkins service status..."
sudo systemctl status jenkins --no-pager

log "Installation script completed!"
