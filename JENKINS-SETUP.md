# Jenkins Installation Guide for Horilla HRMS

This guide provides multiple options to install and configure Jenkins for the Horilla HRMS CI/CD pipeline.

## 🚀 Installation Options

### Option 1: Native Installation (Recommended for Production)

#### Step 1: Install Jenkins
```bash
# Run the installation script
./install-jenkins.sh
```

This script will:
- Install Java 11
- Add Jenkins repository
- Install Jenkins
- Install Docker and Docker Compose
- Install Node.js
- Configure services

#### Step 2: Initial Setup
1. Open Jenkins in your browser: `http://your-server-ip:8080`
2. Use the initial admin password displayed by the script
3. Install suggested plugins
4. Create your admin user

#### Step 3: Install Required Plugins
```bash
# Install plugins for Horilla pipeline
./install-jenkins-plugins.sh
```

### Option 2: Docker Installation (Recommended for Development)

#### Step 1: Start Jenkins with Docker Compose
```bash
# Start Jenkins and supporting services
docker-compose -f docker-compose.jenkins.yml up -d
```

#### Step 2: Access Jenkins
1. Open: `http://localhost:8080`
2. Default credentials: `admin/admin123` (configured in jenkins.yaml)

#### Step 3: Verify Installation
```bash
# Check if all services are running
docker-compose -f docker-compose.jenkins.yml ps
```

## 🔧 Configuration Steps

### 1. Configure Credentials

#### In Jenkins UI:
1. Go to **Manage Jenkins** → **Manage Credentials**
2. Add the following credentials:

**Docker Registry:**
- Type: Username with password
- ID: `docker-registry-credentials`
- Username: Your Docker registry username
- Password: Your Docker registry password

**SSH Keys:**
- Type: SSH Username with private key
- ID: `staging-ssh-key`
- Username: `ubuntu`
- Private Key: Your staging server SSH private key

- Type: SSH Username with private key
- ID: `production-ssh-key`
- Username: `ubuntu`
- Private Key: Your production server SSH private key

**Slack Webhook (Optional):**
- Type: Secret text
- ID: `slack-webhook-url`
- Secret: Your Slack webhook URL

### 2. Configure Global Tools

#### In Jenkins UI:
1. Go to **Manage Jenkins** → **Global Tool Configuration**

**Git:**
- Name: `Default`
- Path to Git executable: `git`

**Node.js:**
- Name: `NodeJS 18`
- Install automatically: ✓
- Version: `18.17.0`

**Python:**
- Name: `Python 3`
- Install automatically: ✓
- Command: `python3`

### 3. Create Pipeline Job

#### Option A: Multibranch Pipeline (Recommended)
1. **New Item** → **Multibranch Pipeline**
2. Name: `horilla-hrms`
3. **Branch Sources** → **GitHub**
4. Repository URL: `https://github.com/your-org/horilla.git`
5. Credentials: Add GitHub credentials
6. **Build Configuration** → **Script Path**: `Jenkinsfile`
7. Save

#### Option B: Pipeline Job
1. **New Item** → **Pipeline**
2. Name: `horilla-hrms-pipeline`
3. **Pipeline** → **Pipeline script from SCM**
4. SCM: Git
5. Repository URL: `https://github.com/your-org/horilla.git`
6. Script Path: `Jenkinsfile`
7. Save

## 🔍 Verification Steps

### 1. Test Jenkins Installation
```bash
# Check Jenkins service status
sudo systemctl status jenkins

# Check if Jenkins is accessible
curl -I http://localhost:8080
```

### 2. Test Docker Integration
```bash
# Check if Jenkins can access Docker
sudo -u jenkins docker ps

# Test Docker Compose
sudo -u jenkins docker-compose --version
```

### 3. Test Pipeline
1. Trigger a build manually
2. Check build logs
3. Verify all stages complete successfully

## 🛠️ Troubleshooting

### Common Issues

#### Jenkins Won't Start
```bash
# Check logs
sudo journalctl -u jenkins -f

# Check Java installation
java -version

# Check port availability
sudo netstat -tlnp | grep :8080
```

#### Docker Permission Issues
```bash
# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

#### Plugin Installation Failures
```bash
# Check Jenkins logs
sudo tail -f /var/log/jenkins/jenkins.log

# Manual plugin installation
# Download .hpi files and place in /var/lib/jenkins/plugins/
```

#### Pipeline Failures
```bash
# Check workspace permissions
sudo chown -R jenkins:jenkins /var/lib/jenkins/workspace/

# Check Git access
sudo -u jenkins git clone https://github.com/your-org/horilla.git /tmp/test-clone
```

### Log Locations
- Jenkins logs: `/var/log/jenkins/jenkins.log`
- Jenkins home: `/var/lib/jenkins/`
- Build logs: Available in Jenkins UI

## 🔒 Security Configuration

### 1. Enable Security
1. **Manage Jenkins** → **Configure Global Security**
2. **Security Realm**: Jenkins' own user database
3. **Authorization**: Matrix-based security
4. Configure user permissions

### 2. Configure HTTPS (Production)
```bash
# Generate SSL certificate
sudo openssl req -newkey rsa:2048 -nodes -keyout jenkins.key -x509 -days 365 -out jenkins.crt

# Configure Jenkins for HTTPS
sudo nano /etc/default/jenkins
# Add: JENKINS_ARGS="--httpPort=-1 --httpsPort=8443 --httpsKeyStore=/path/to/keystore"
```

### 3. Firewall Configuration
```bash
# Allow Jenkins port
sudo ufw allow 8080/tcp

# For HTTPS
sudo ufw allow 8443/tcp
```

## 📊 Monitoring Setup

### 1. Enable Prometheus Metrics
1. Install **Prometheus metrics plugin**
2. **Manage Jenkins** → **Configure System**
3. **Prometheus** → Enable metrics collection

### 2. Configure Monitoring
```bash
# Add monitoring configuration to docker-compose
# See docker-compose.prod.yml for Prometheus/Grafana setup
```

## 🔄 Backup and Maintenance

### 1. Backup Jenkins Configuration
```bash
# Backup Jenkins home directory
sudo tar -czf jenkins-backup-$(date +%Y%m%d).tar.gz /var/lib/jenkins/

# Backup to remote location
rsync -av /var/lib/jenkins/ user@backup-server:/backups/jenkins/
```

### 2. Regular Maintenance
```bash
# Update Jenkins
sudo apt update && sudo apt upgrade jenkins

# Clean old builds
# Configure in Jenkins UI: Manage Jenkins → System Configuration
```

## 📚 Additional Resources

- [Jenkins Official Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Pipeline Plugin](https://plugins.jenkins.io/docker-workflow/)
- [Configuration as Code Plugin](https://plugins.jenkins.io/configuration-as-code/)

## 🆘 Support

If you encounter issues:
1. Check the troubleshooting section above
2. Review Jenkins logs
3. Check the Horilla CI/CD documentation
4. Create an issue in the project repository

---

**Next Steps:**
1. Complete Jenkins installation using one of the methods above
2. Configure credentials and tools
3. Create the pipeline job
4. Test the pipeline with a sample commit
5. Configure monitoring and notifications

The Jenkins setup is now ready for the Horilla HRMS CI/CD pipeline!
