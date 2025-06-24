#!/bin/bash

# Horilla HRMS Test Runner Script
# This script runs all tests including unit, integration, and code quality checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Configuration
TEST_DB_NAME="${TEST_DB_NAME:-horilla_test}"
TEST_DB_USER="${TEST_DB_USER:-horilla_test}"
TEST_DB_PASSWORD="${TEST_DB_PASSWORD:-test_password}"

# Activate virtual environment
if [[ -f "venv/bin/activate" ]]; then
    source venv/bin/activate
    log "Activated Python virtual environment"
elif [[ -f "horillavenv/bin/activate" ]]; then
    source horillavenv/bin/activate
    log "Activated Python virtual environment"
else
    warn "No virtual environment found, using system Python"
fi

# Install test dependencies
log "Installing test dependencies..."
pip install -q pytest pytest-django pytest-cov flake8 black isort safety bandit coverage

# Setup test database
log "Setting up test database..."
sudo -u postgres createdb "$TEST_DB_NAME" 2>/dev/null || true
sudo -u postgres psql -c "CREATE USER $TEST_DB_USER WITH PASSWORD '$TEST_DB_PASSWORD';" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $TEST_DB_NAME TO $TEST_DB_USER;" 2>/dev/null || true

# Create test environment file
log "Creating test environment configuration..."
cp .env.dist .env.test
sed -i "s/DB_NAME=horilla_main/DB_NAME=$TEST_DB_NAME/" .env.test
sed -i "s/DB_USER=horilla/DB_USER=$TEST_DB_USER/" .env.test
sed -i "s/DB_PASSWORD=horilla/DB_PASSWORD=$TEST_DB_PASSWORD/" .env.test
sed -i "s/DEBUG=True/DEBUG=False/" .env.test

# Export test environment
export DJANGO_SETTINGS_MODULE=horilla.settings
export DATABASE_URL="postgresql://$TEST_DB_USER:$TEST_DB_PASSWORD@localhost:5432/$TEST_DB_NAME"

# Run code quality checks
log "Running code quality checks..."

info "Running flake8 linting..."
flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics --output-file=flake8-report.txt || warn "Flake8 found issues"

info "Checking code formatting with black..."
black --check --diff . > black-report.txt 2>&1 || warn "Black formatting issues found"

info "Checking import sorting with isort..."
isort --check-only --diff . > isort-report.txt 2>&1 || warn "Import sorting issues found"

# Security checks
log "Running security checks..."

info "Running safety check for known vulnerabilities..."
safety check --json --output safety-report.json || warn "Safety check found vulnerabilities"

info "Running bandit security analysis..."
bandit -r . -f json -o bandit-report.json || warn "Bandit found security issues"

# Database migrations
log "Running database migrations..."
python manage.py migrate --settings=horilla.settings

# Run Django tests
log "Running Django unit tests..."
python manage.py test --settings=horilla.settings --verbosity=2 --keepdb

# Run pytest tests
log "Running pytest tests..."
pytest --verbose --tb=short --cov=. --cov-report=html --cov-report=xml --cov-report=term-missing --junitxml=test-results.xml

# Generate coverage report
log "Generating coverage reports..."
coverage combine 2>/dev/null || true
coverage report --show-missing
coverage html -d htmlcov/
coverage xml -o coverage.xml

# Performance tests (if they exist)
if [[ -d "tests/performance" ]]; then
    log "Running performance tests..."
    pytest tests/performance/ -v --junitxml=performance-test-results.xml || warn "Performance tests failed"
fi

# Integration tests (if they exist)
if [[ -d "tests/integration" ]]; then
    log "Running integration tests..."
    pytest tests/integration/ -v --junitxml=integration-test-results.xml || warn "Integration tests failed"
fi

# Cleanup test database
log "Cleaning up test database..."
sudo -u postgres dropdb "$TEST_DB_NAME" 2>/dev/null || true
sudo -u postgres dropuser "$TEST_DB_USER" 2>/dev/null || true

# Generate test summary
log "Generating test summary..."
cat > test-summary.txt << EOF
Horilla HRMS Test Summary
========================
Date: $(date)
Environment: Test

Code Quality:
- Flake8: $(if [[ -f flake8-report.txt ]]; then echo "✓ Completed"; else echo "✗ Failed"; fi)
- Black: $(if [[ -f black-report.txt ]]; then echo "✓ Completed"; else echo "✗ Failed"; fi)
- isort: $(if [[ -f isort-report.txt ]]; then echo "✓ Completed"; else echo "✗ Failed"; fi)

Security:
- Safety: $(if [[ -f safety-report.json ]]; then echo "✓ Completed"; else echo "✗ Failed"; fi)
- Bandit: $(if [[ -f bandit-report.json ]]; then echo "✓ Completed"; else echo "✗ Failed"; fi)

Tests:
- Unit Tests: $(if [[ -f test-results.xml ]]; then echo "✓ Completed"; else echo "✗ Failed"; fi)
- Coverage: $(if [[ -f coverage.xml ]]; then echo "✓ Generated"; else echo "✗ Failed"; fi)

Reports Generated:
- HTML Coverage Report: htmlcov/index.html
- XML Coverage Report: coverage.xml
- Test Results: test-results.xml
- Security Reports: bandit-report.json, safety-report.json
EOF

log "Test execution completed!"
info "Check test-summary.txt for detailed results"

# Display coverage summary
if command -v coverage &> /dev/null; then
    echo ""
    log "Coverage Summary:"
    coverage report --show-missing | tail -n 1
fi
