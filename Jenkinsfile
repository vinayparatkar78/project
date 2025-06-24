pipeline {
  agent any

  // No polling here—GitHub webhook will fire it
  triggers {
    githubPush()
  }

  environment {
    IMAGE_NAME = "horilla_web"
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/vinayparatkar78/project.git',
            credentialsId: 'github-horila-creds',
            branch: 'main'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          docker.build("${IMAGE_NAME}:${IMAGE_TAG}")
        }
      }
    }

    stage('Deploy with Docker‑Compose') {
      steps {
        sh 'docker-compose down || true'
        sh 'docker-compose up -d --build'
      }
    }
  }

  post {
    success {
      echo " Build and deployment successful!"
    }
    failure {
      echo " Build or deployment failed."
    }
  }
}
