pipeline {
  agent any

  triggers {
    githubPush()
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/vinayparatkar78/project.git', branch: 'main'
      }
    }

    stage('Run Docker Compose') {
      steps {
        script {
          sh """
          docker-compose down || true
          docker-compose up -d --build
          """
        }
      }
    }
  }

  post {
    success {
      echo 'Deployment Successful!'
    }
    failure {
      echo 'Deployment Failed!'
    }
  }
}
