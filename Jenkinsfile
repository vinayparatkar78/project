pipeline {
  agent any

  triggers {
    githubPush()   // This will trigger pipeline on every GitHub push
  }

  environment {
    IMAGE_NAME = "horila-app"
    IMAGE_TAG  = "${env.BUILD_NUMBER}"  // Jenkins build number as image tag
  }

  stages {
    stage('Checkout') {
      steps {
        git url: 'https://github.com/vinayparatkar78/project.git',
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

    stage('Stop Running Containers') {
      steps {
        script {
          sh """
          docker stop horila-web || true
          docker rm horila-web || true
          """
        }
      }
    }

    stage('Run Container') {
      steps {
        script {
          sh """
          docker run -d --name horila-web -p 8000:8000 ${IMAGE_NAME}:${IMAGE_TAG}
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

