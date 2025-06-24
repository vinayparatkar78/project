#!/usr/bin/env groovy

/**
 * Horilla HRMS Deployment Pipeline Shared Library
 * This library contains reusable functions for the Horilla CI/CD pipeline
 */

def call(Map config) {
    pipeline {
        agent any
        
        environment {
            DOCKER_REGISTRY = config.dockerRegistry ?: 'your-registry.com'
            DOCKER_IMAGE = config.dockerImage ?: 'horilla-hrms'
            STAGING_SERVER = config.stagingServer ?: 'staging.horilla.com'
            PRODUCTION_SERVER = config.productionServer ?: 'production.horilla.com'
        }
        
        stages {
            stage('Setup') {
                steps {
                    setupEnvironment(config)
                }
            }
            
            stage('Test') {
                steps {
                    runTests(config)
                }
            }
            
            stage('Build') {
                when {
                    anyOf {
                        branch 'main'
                        branch 'master'
                        branch 'develop'
                    }
                }
                steps {
                    buildDockerImage(config)
                }
            }
            
            stage('Deploy') {
                steps {
                    deployApplication(config)
                }
            }
        }
        
        post {
            always {
                publishTestResults testResultsPattern: '**/*test-results.xml'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'htmlcov',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
                cleanWs()
            }
        }
    }
}

def setupEnvironment(Map config) {
    sh '''
        # Setup Python environment
        python3 -m venv venv
        source venv/bin/activate
        pip install --upgrade pip
        pip install -r requirements.txt
        
        # Setup Node.js environment
        npm ci
        npm run development
        
        # Setup test database
        sudo -u postgres createdb horilla_test || true
        sudo -u postgres psql -c "CREATE USER horilla_test WITH PASSWORD 'test_password';" || true
        sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE horilla_test TO horilla_test;" || true
    '''
}

def runTests(Map config) {
    sh '''
        source venv/bin/activate
        
        # Run the comprehensive test suite
        ./scripts/run_tests.sh
    '''
}

def buildDockerImage(Map config) {
    script {
        def dockerImage = docker.build("${env.DOCKER_IMAGE}:${env.BUILD_NUMBER}")
        
        docker.withRegistry("https://${env.DOCKER_REGISTRY}", config.dockerCredentials) {
            dockerImage.push()
            dockerImage.push('latest')
        }
    }
}

def deployApplication(Map config) {
    script {
        def environment = env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master' ? 'production' : 'staging'
        def server = environment == 'production' ? env.PRODUCTION_SERVER : env.STAGING_SERVER
        def credentials = environment == 'production' ? config.productionCredentials : config.stagingCredentials
        
        sshagent([credentials]) {
            sh """
                ssh -o StrictHostKeyChecking=no ubuntu@${server} '
                    cd /opt/horilla &&
                    export BUILD_TAG=${env.BUILD_NUMBER} &&
                    ./scripts/deploy.sh ${environment}
                '
            """
        }
    }
}

def sendNotification(String message, String color = 'good') {
    if (env.SLACK_WEBHOOK_URL) {
        slackSend(
            channel: '#deployments',
            color: color,
            message: message
        )
    }
}

return this
