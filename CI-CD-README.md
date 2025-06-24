# Horilla HRMS CI/CD Pipeline

This document describes the comprehensive CI/CD pipeline setup for the Horilla HRMS project using Jenkins, Docker, and automated deployment strategies.

## 🚀 Pipeline Overview

The CI/CD pipeline includes:
- **Automated Testing**: Unit tests, integration tests, code quality checks
- **Security Scanning**: Vulnerability detection and static analysis
- **Docker Build**: Containerized application builds
- **Multi-Environment Deployment**: Staging and production environments
- **Health Monitoring**: Application health checks and monitoring
- **Rollback Capability**: Automated rollback on deployment failures

## 📁 Pipeline Files

### Core Pipeline Files
- `Jenkinsfile` - Main Jenkins pipeline configuration
- `Jenkinsfile.simple` - Simplified pipeline using shared library
- `docker-compose.ci.yml` - CI/CD specific Docker Compose
- `docker-compose.staging.yml` - Staging environment configuration
- `docker-compose.prod.yml` - Production environment configuration

### Scripts
- `scripts/deploy.sh` - Deployment script with rollback capability
- `scripts/run_tests.sh` - Comprehensive test runner
- `jenkins/shared-library/vars/horillaDeployment.groovy` - Reusable pipeline functions

### Configuration Files
- `pytest.ini` - Python testing configuration
- `setup.cfg` - Code quality tools configuration
- `horilla/health.py` - Enhanced health check endpoint

## 🛠️ Setup Instructions

### 1. Jenkins Configuration

#### Prerequisites
- Jenkins server with Docker support
- Required plugins:
  - Docker Pipeline
  - SSH Agent
  - Slack Notification
  - HTML Publisher
  - Coverage Publisher

#### Credentials Setup
Configure the following credentials in Jenkins:

```bash
# Docker Registry
DOCKER_REGISTRY_CREDENTIALS = 'docker-registry-credentials'

# SSH Keys for deployment
STAGING_SSH_CREDENTIALS = 'staging-ssh-key'
PRODUCTION_SSH_CREDENTIALS = 'production-ssh-key'

# Database credentials
DATABASE_CREDENTIALS = 'database-credentials'

# Slack webhook (optional)
SLACK_WEBHOOK_URL = 'your-slack-webhook-url'
```

#### Environment Variables
Set these in Jenkins global configuration:

```bash
DOCKER_REGISTRY=your-registry.com
STAGING_SERVER=staging.horilla.com
PRODUCTION_SERVER=production.horilla.com
```

### 2. Server Setup

#### Staging Server Setup
```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Create application directory
sudo mkdir -p /opt/horilla-staging
sudo chown ubuntu:ubuntu /opt/horilla-staging

# Clone repository
cd /opt/horilla-staging
git clone https://github.com/your-org/horilla.git .

# Setup environment variables
cp .env.dist .env
# Edit .env with staging-specific values
```

#### Production Server Setup
```bash
# Similar to staging but use /opt/horilla directory
sudo mkdir -p /opt/horilla
sudo chown ubuntu:ubuntu /opt/horilla

# Additional production setup
sudo mkdir -p /opt/horilla/backups
sudo mkdir -p /opt/horilla/logs
```

### 3. Database Setup

#### PostgreSQL Configuration
```sql
-- Staging database
CREATE DATABASE horilla_staging;
CREATE USER horilla_staging WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE horilla_staging TO horilla_staging;

-- Production database
CREATE DATABASE horilla_main;
CREATE USER horilla WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE horilla_main TO horilla;
```

## 🔄 Pipeline Stages

### 1. Checkout
- Clean workspace
- Checkout source code
- Generate build tags

### 2. Environment Setup
- **Python Environment**: Virtual environment, dependencies
- **Node.js Environment**: NPM dependencies, asset building
- **Database Setup**: Test database creation

### 3. Code Quality & Security
- **Linting**: flake8, black, isort
- **Security Scanning**: safety, bandit
- **Dependency Checks**: Known vulnerabilities

### 4. Testing
- **Unit Tests**: Django test suite
- **Coverage Analysis**: Code coverage reporting
- **Integration Tests**: End-to-end testing

### 5. Build
- **Docker Image**: Multi-stage Docker build
- **Registry Push**: Tagged image deployment
- **Artifact Storage**: Build artifacts archival

### 6. Deployment
- **Staging**: Automatic deployment on develop branch
- **Production**: Manual approval required
- **Health Checks**: Post-deployment verification
- **Rollback**: Automatic rollback on failure

## 🧪 Testing Strategy

### Test Types
1. **Unit Tests**: Individual component testing
2. **Integration Tests**: Component interaction testing
3. **Security Tests**: Vulnerability scanning
4. **Performance Tests**: Load and stress testing
5. **Smoke Tests**: Basic functionality verification

### Running Tests Locally
```bash
# Run all tests
./scripts/run_tests.sh

# Run specific test types
python manage.py test
pytest tests/unit/
pytest tests/integration/
```

### Coverage Requirements
- Minimum coverage: 80%
- Critical paths: 95%
- New code: 90%

## 🚀 Deployment Process

### Staging Deployment
- Triggered on: `develop` branch commits
- Automatic deployment
- Integration tests run post-deployment
- Slack notifications

### Production Deployment
- Triggered on: `main`/`master` branch commits
- Manual approval required
- Database backup before deployment
- Blue-green deployment strategy
- Health checks and monitoring
- Automatic rollback on failure

### Deployment Commands
```bash
# Manual deployment
./scripts/deploy.sh staging
./scripts/deploy.sh production

# Using Docker Compose
docker-compose -f docker-compose.staging.yml up -d
docker-compose -f docker-compose.prod.yml up -d
```

## 📊 Monitoring & Health Checks

### Health Check Endpoint
- URL: `/health/`
- Checks: Database, Cache, Application status
- Response: JSON with detailed status

### Monitoring Stack (Production)
- **Prometheus**: Metrics collection
- **Grafana**: Visualization and alerting
- **Nginx**: Access logs and performance
- **Application**: Custom metrics and logging

### Key Metrics
- Response time
- Error rates
- Database performance
- Resource utilization
- User activity

## 🔧 Troubleshooting

### Common Issues

#### Pipeline Failures
```bash
# Check Jenkins logs
tail -f /var/log/jenkins/jenkins.log

# Check Docker logs
docker-compose logs web
docker-compose logs db
```

#### Deployment Issues
```bash
# Check deployment logs
./scripts/deploy.sh staging 2>&1 | tee deploy.log

# Manual rollback
docker-compose down
docker-compose up -d
```

#### Database Issues
```bash
# Check database connectivity
docker-compose exec db psql -U horilla -d horilla_main -c "SELECT 1;"

# Restore from backup
docker-compose exec db psql -U horilla -d horilla_main < backup_file.sql
```

### Log Locations
- Jenkins: `/var/log/jenkins/`
- Application: `./logs/`
- Nginx: `./logs/nginx/`
- Database: Docker container logs

## 🔒 Security Considerations

### Pipeline Security
- Encrypted credentials storage
- Secure Docker registry
- SSH key management
- Environment variable protection

### Application Security
- Regular dependency updates
- Security scanning in CI/CD
- SSL/TLS encryption
- Database security
- Access control

### Best Practices
- Principle of least privilege
- Regular security audits
- Automated vulnerability scanning
- Secure coding practices
- Regular backups

## 📈 Performance Optimization

### Build Optimization
- Docker layer caching
- Parallel pipeline stages
- Incremental builds
- Artifact caching

### Deployment Optimization
- Blue-green deployments
- Rolling updates
- Health check optimization
- Resource allocation

### Application Optimization
- Static file optimization
- Database query optimization
- Caching strategies
- CDN integration

## 🤝 Contributing

### Pipeline Changes
1. Test changes in feature branch
2. Update documentation
3. Review security implications
4. Test in staging environment
5. Create pull request

### Adding New Tests
1. Follow existing test patterns
2. Maintain coverage requirements
3. Update test documentation
4. Include in CI/CD pipeline

## 📞 Support

For CI/CD pipeline issues:
- Check this documentation
- Review Jenkins logs
- Contact DevOps team
- Create GitHub issue

## 📚 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Django Testing](https://docs.djangoproject.com/en/4.2/topics/testing/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)

---

**Last Updated**: June 2024
**Version**: 1.0
**Maintainer**: DevOps Team
