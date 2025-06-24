pipeline {
    agent any
    
    environment {
        // Environment variables
        PYTHON_VERSION = '3.9'
        NODE_VERSION = '18'
        POSTGRES_DB = 'horilla_test'
        POSTGRES_USER = 'horilla_test'
        POSTGRES_PASSWORD = 'test_password'
        POSTGRES_HOST = 'localhost'
        POSTGRES_PORT = '5432'
        
        // Docker registry (customize as needed)
        DOCKER_REGISTRY = 'your-registry.com'
        DOCKER_IMAGE = 'horilla-hrms'
        
        // Deployment environments
        STAGING_SERVER = 'staging.horilla.com'
        PRODUCTION_SERVER = 'production.horilla.com'
        
        // Credentials IDs (configure in Jenkins)
        DOCKER_REGISTRY_CREDENTIALS = 'docker-registry-credentials'
        STAGING_SSH_CREDENTIALS = 'staging-ssh-key'
        PRODUCTION_SSH_CREDENTIALS = 'production-ssh-key'
        DATABASE_CREDENTIALS = 'database-credentials'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timeout(time: 30, unit: 'MINUTES')
        timestamps()
        skipDefaultCheckout()
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    // Clean workspace and checkout code
                    cleanWs()
                    checkout scm
                    
                    // Get commit information
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    
                    env.BUILD_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Setup Environment') {
            parallel {
                stage('Python Environment') {
                    steps {
                        script {
                            sh '''
                                # Create Python virtual environment
                                python3 -m venv venv
                                source venv/bin/activate
                                
                                # Upgrade pip and install dependencies
                                pip install --upgrade pip
                                pip install -r requirements.txt
                                
                                # Install additional testing dependencies
                                pip install pytest pytest-django pytest-cov flake8 black isort
                            '''
                        }
                    }
                }
                
                stage('Node.js Environment') {
                    steps {
                        script {
                            sh '''
                                # Install Node.js dependencies
                                npm ci
                                
                                # Build frontend assets
                                npm run development
                            '''
                        }
                    }
                }
                
                stage('Database Setup') {
                    steps {
                        script {
                            sh '''
                                # Setup test database
                                sudo -u postgres createdb ${POSTGRES_DB} || true
                                sudo -u postgres psql -c "CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';" || true
                                sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};" || true
                            '''
                        }
                    }
                }
            }
        }
        
        stage('Code Quality & Security') {
            parallel {
                stage('Linting') {
                    steps {
                        script {
                            sh '''
                                source venv/bin/activate
                                
                                # Python linting
                                echo "Running flake8..."
                                flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics || true
                                
                                # Check code formatting
                                echo "Checking code formatting with black..."
                                black --check . || true
                                
                                # Check import sorting
                                echo "Checking import sorting with isort..."
                                isort --check-only . || true
                            '''
                        }
                    }
                    post {
                        always {
                            // Archive linting reports
                            archiveArtifacts artifacts: '**/*.log', allowEmptyArchive: true
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        script {
                            sh '''
                                source venv/bin/activate
                                
                                # Install security scanning tools
                                pip install safety bandit
                                
                                # Check for known security vulnerabilities in dependencies
                                echo "Running safety check..."
                                safety check || true
                                
                                # Static security analysis
                                echo "Running bandit security scan..."
                                bandit -r . -f json -o bandit-report.json || true
                            '''
                        }
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: 'bandit-report.json', allowEmptyArchive: true
                        }
                    }
                }
            }
        }
        
        stage('Testing') {
            steps {
                script {
                    sh '''
                        source venv/bin/activate
                        
                        # Create test environment file
                        cp .env.dist .env.test
                        sed -i "s/DB_NAME=horilla_main/DB_NAME=${POSTGRES_DB}/" .env.test
                        sed -i "s/DB_USER=horilla/DB_USER=${POSTGRES_USER}/" .env.test
                        sed -i "s/DB_PASSWORD=horilla/DB_PASSWORD=${POSTGRES_PASSWORD}/" .env.test
                        sed -i "s/DEBUG=True/DEBUG=False/" .env.test
                        
                        # Run Django tests
                        export DJANGO_SETTINGS_MODULE=horilla.settings
                        export DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@${POSTGRES_HOST}:${POSTGRES_PORT}/${POSTGRES_DB}
                        
                        # Run migrations
                        python manage.py migrate --settings=horilla.settings
                        
                        # Run tests with coverage
                        python manage.py test --settings=horilla.settings --verbosity=2
                        
                        # Generate coverage report
                        coverage run --source='.' manage.py test --settings=horilla.settings
                        coverage xml -o coverage.xml
                        coverage html -d htmlcov/
                    '''
                }
            }
            post {
                always {
                    // Publish test results
                    publishTestResults testResultsPattern: 'test-results.xml'
                    
                    // Publish coverage reports
                    publishCoverageResults([
                        [
                            path: 'coverage.xml',
                            type: 'COBERTURA'
                        ]
                    ])
                    
                    // Archive coverage HTML report
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'htmlcov',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }
        
        stage('Build Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'master'
                    branch 'develop'
                    changeRequest()
                }
            }
            steps {
                script {
                    // Build Docker image
                    def dockerImage = docker.build("${DOCKER_IMAGE}:${BUILD_TAG}")
                    
                    // Tag with latest if on main/master branch
                    if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                        dockerImage.tag('latest')
                    }
                    
                    // Push to registry
                    docker.withRegistry("https://${DOCKER_REGISTRY}", DOCKER_REGISTRY_CREDENTIALS) {
                        dockerImage.push()
                        if (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') {
                            dockerImage.push('latest')
                        }
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                anyOf {
                    branch 'develop'
                    changeRequest()
                }
            }
            steps {
                script {
                    sshagent([STAGING_SSH_CREDENTIALS]) {
                        sh '''
                            # Deploy to staging server
                            ssh -o StrictHostKeyChecking=no ubuntu@${STAGING_SERVER} "
                                cd /opt/horilla &&
                                docker-compose pull &&
                                docker-compose up -d &&
                                docker-compose exec -T web python manage.py migrate &&
                                docker-compose exec -T web python manage.py collectstatic --noinput
                            "
                        '''
                    }
                }
            }
            post {
                success {
                    // Send notification about successful staging deployment
                    slackSend(
                        channel: '#deployments',
                        color: 'good',
                        message: "✅ Horilla deployed to staging successfully! Build: ${BUILD_TAG}"
                    )
                }
                failure {
                    slackSend(
                        channel: '#deployments',
                        color: 'danger',
                        message: "❌ Horilla staging deployment failed! Build: ${BUILD_TAG}"
                    )
                }
            }
        }
        
        stage('Integration Tests') {
            when {
                anyOf {
                    branch 'develop'
                    changeRequest()
                }
            }
            steps {
                script {
                    sh '''
                        # Run integration tests against staging environment
                        source venv/bin/activate
                        
                        # Install additional testing tools
                        pip install selenium requests
                        
                        # Run integration tests
                        python -m pytest tests/integration/ -v --junitxml=integration-test-results.xml || true
                    '''
                }
            }
            post {
                always {
                    publishTestResults testResultsPattern: 'integration-test-results.xml'
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                allOf {
                    anyOf {
                        branch 'main'
                        branch 'master'
                    }
                    not { changeRequest() }
                }
            }
            steps {
                script {
                    // Manual approval for production deployment
                    timeout(time: 5, unit: 'MINUTES') {
                        input message: 'Deploy to Production?', ok: 'Deploy',
                              submitterParameter: 'DEPLOYER'
                    }
                    
                    sshagent([PRODUCTION_SSH_CREDENTIALS]) {
                        sh '''
                            # Deploy to production server
                            ssh -o StrictHostKeyChecking=no ubuntu@${PRODUCTION_SERVER} "
                                cd /opt/horilla &&
                                
                                # Backup database before deployment
                                docker-compose exec -T db pg_dump -U horilla horilla_main > backup_\$(date +%Y%m%d_%H%M%S).sql &&
                                
                                # Deploy new version
                                docker-compose pull &&
                                docker-compose up -d &&
                                
                                # Run migrations
                                docker-compose exec -T web python manage.py migrate &&
                                
                                # Collect static files
                                docker-compose exec -T web python manage.py collectstatic --noinput &&
                                
                                # Health check
                                sleep 30 &&
                                curl -f http://localhost:8000/health/ || exit 1
                            "
                        '''
                    }
                }
            }
            post {
                success {
                    slackSend(
                        channel: '#deployments',
                        color: 'good',
                        message: "🚀 Horilla deployed to production successfully! Build: ${BUILD_TAG} by ${env.DEPLOYER}"
                    )
                }
                failure {
                    slackSend(
                        channel: '#deployments',
                        color: 'danger',
                        message: "💥 Horilla production deployment failed! Build: ${BUILD_TAG} - URGENT!"
                    )
                }
            }
        }
    }
    
    post {
        always {
            // Clean up
            sh '''
                # Clean up Docker images
                docker image prune -f || true
                
                # Clean up test database
                sudo -u postgres dropdb ${POSTGRES_DB} || true
                sudo -u postgres dropuser ${POSTGRES_USER} || true
            '''
            
            // Archive artifacts
            archiveArtifacts artifacts: '**/*.log, **/*.xml, **/*.json', allowEmptyArchive: true
            
            // Clean workspace
            cleanWs()
        }
        
        success {
            echo 'Pipeline completed successfully!'
        }
        
        failure {
            // Send failure notification
            slackSend(
                channel: '#ci-cd',
                color: 'danger',
                message: "❌ Horilla pipeline failed! Branch: ${env.BRANCH_NAME}, Build: ${BUILD_TAG}"
            )
        }
        
        unstable {
            slackSend(
                channel: '#ci-cd',
                color: 'warning',
                message: "⚠️ Horilla pipeline unstable! Branch: ${env.BRANCH_NAME}, Build: ${BUILD_TAG}"
            )
        }
    }
}
