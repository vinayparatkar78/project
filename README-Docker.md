# Horilla HRMS - Docker Setup

This guide explains how to run Horilla HRMS using Docker and Docker Compose.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- At least 2GB RAM available
- At least 5GB disk space

## Quick Start

### 1. Clone and Setup

```bash
git clone https://github.com/horilla-opensource/horilla.git
cd horilla
```

### 2. Environment Configuration

Copy the Docker environment file:
```bash
cp .env.docker .env
```

Edit `.env` file to customize your settings:
```bash
nano .env
```

### 3. Build and Run

For production:
```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f web
```

For development:
```bash
# Use development compose file
docker-compose -f docker-compose.dev.yml up -d
```

### 4. Access Application

- **Web Application**: http://localhost:8000
- **With Nginx** (production): http://localhost
- **Database**: localhost:5432 (if needed)
- **Redis**: localhost:6379 (if needed)

## Docker Compose Files

### `docker-compose.yml` (Production)
- Optimized for production use
- Includes Nginx reverse proxy
- Uses multi-stage Docker build
- Includes health checks
- Persistent volumes for data

### `docker-compose.dev.yml` (Development)
- Optimized for development
- Hot reload enabled
- Debug mode on
- Direct access to application

## Services

### Web Application (`web`)
- **Image**: Built from Dockerfile
- **Port**: 8000
- **Environment**: Configurable via .env
- **Volumes**: Media and static files
- **Health Check**: HTTP endpoint

### Database (`db`)
- **Image**: PostgreSQL 15 Alpine
- **Port**: 5432
- **Data**: Persistent volume
- **Health Check**: pg_isready

### Redis (`redis`)
- **Image**: Redis 7 Alpine
- **Port**: 6379
- **Data**: Persistent volume
- **Health Check**: Redis ping

### Nginx (`nginx`) - Production Only
- **Image**: Nginx Alpine
- **Ports**: 80, 443
- **Purpose**: Reverse proxy, static files
- **Profile**: production

## Docker Commands

### Basic Operations

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# View logs
docker-compose logs -f [service_name]

# Restart a service
docker-compose restart [service_name]

# Scale web service
docker-compose up -d --scale web=3
```

### Database Operations

```bash
# Run migrations
docker-compose exec web python manage.py migrate

# Create superuser
docker-compose exec web python manage.py createsuperuser

# Access database
docker-compose exec db psql -U horilla -d horilla_main

# Backup database
docker-compose exec db pg_dump -U horilla horilla_main > backup.sql

# Restore database
docker-compose exec -T db psql -U horilla horilla_main < backup.sql
```

### Development Commands

```bash
# Install new packages
docker-compose exec web pip install package_name
docker-compose exec web pip freeze > requirements.txt

# Run Django commands
docker-compose exec web python manage.py collectstatic
docker-compose exec web python manage.py shell

# Access container shell
docker-compose exec web bash
```

## Production Deployment

### 1. Environment Setup

```bash
# Copy and edit production environment
cp .env.docker .env
nano .env

# Set production values
DEBUG=False
SECRET_KEY=your-secure-secret-key
ALLOWED_HOSTS=your-domain.com,www.your-domain.com
```

### 2. SSL Configuration

Create SSL certificates directory:
```bash
mkdir ssl
# Place your SSL certificates in ./ssl/
```

### 3. Start with Nginx

```bash
# Start with production profile
docker-compose --profile production up -d
```

### 4. Initial Setup

```bash
# Initialize database (first time only)
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py collectstatic --noinput
docker-compose exec web python manage.py compilemessages
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check service health
docker-compose ps

# View health check logs
docker inspect horilla_web | grep -A 10 Health
```

### Log Management

```bash
# View logs with timestamps
docker-compose logs -f -t

# Limit log output
docker-compose logs --tail=100 web

# Save logs to file
docker-compose logs web > horilla.log
```

### Backup Strategy

```bash
# Create backup script
cat > backup.sh << 'EOF'
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
docker-compose exec -T db pg_dump -U horilla horilla_main > "backup_${DATE}.sql"
docker run --rm -v horilla_media_files:/data -v $(pwd):/backup alpine tar czf /backup/media_${DATE}.tar.gz -C /data .
EOF

chmod +x backup.sh
./backup.sh
```

## Troubleshooting

### Common Issues

1. **Database Connection Error**
   ```bash
   # Check database status
   docker-compose logs db
   
   # Restart database
   docker-compose restart db
   ```

2. **Permission Issues**
   ```bash
   # Fix file permissions
   sudo chown -R $USER:$USER .
   ```

3. **Port Already in Use**
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :8000
   
   # Use different port
   docker-compose up -d -p 8080:8000
   ```

4. **Out of Disk Space**
   ```bash
   # Clean up Docker
   docker system prune -a
   docker volume prune
   ```

### Performance Tuning

1. **Increase Worker Processes**
   ```bash
   # Edit docker-compose.yml
   command: ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "horilla.wsgi:application"]
   ```

2. **Database Optimization**
   ```bash
   # Add to docker-compose.yml db service
   command: postgres -c shared_preload_libraries=pg_stat_statements -c pg_stat_statements.track=all
   ```

## Security Considerations

1. **Change Default Passwords**
2. **Use Strong Secret Keys**
3. **Enable HTTPS in Production**
4. **Regular Security Updates**
5. **Backup Encryption**
6. **Network Security**

## Support

For issues and questions:
- GitHub Issues: https://github.com/horilla-opensource/horilla/issues
- Documentation: https://www.horilla.com/
- Community: Join our community channels

## License

This project is licensed under the AGPL License - see the LICENSE file for details.
