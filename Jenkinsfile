pipeline {
  agent {
    label "swarm"
  }
  stages {
    stage("Pull") {
      steps {
        sh '''ls -al
              git branch
           '''
      }
    }
  }
  post {
    always {
      echo "CleaningUp work directory"
      deleteDir()
    }
  }
}
