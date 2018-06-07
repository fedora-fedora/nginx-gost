pipeline {
  agent {
    label "swarm"
  }
  stages {
    stage("Pull") {
      steps {
        ansiColor('xterm') {
          withCredentials([sshUserPrivateKey(credentialsId: 'provision', keyFileVariable: 'GIT_SSH_KEY', passphraseVariable: '', usernameVariable: 'GIT_SSH_USERNAME')]) {
            sh '''GIT_SSH_COMMAND='ssh -i ${GIT_SSH_KEY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
                  git clone https://git.sdsys.ru/iru/nginx-gost.git
               '''
          }
        }
        withCredentials([sshUserPrivateKey(credentialsId: 'provision', keyFileVariable: 'GIT_SSH_KEY', passphraseVariable: '', usernameVariable: 'GIT_SSH_USERNAME')]) {
          sh '''GIT_SSH_COMMAND='ssh -i ${GIT_SSH_KEY} -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no' \
                git clone ssh://git@git.sdsys.ru:8022/sdsys/pki.git ${WORKSPACE}/pki
             '''
        }
        ansiColor('xterm') {
          ansiblePlaybook(
            playbook: '${WORKSPACE}/ansible/generate.configs.yml',
            extraVars: [
              target_dir: '${WORKSPACE}',
            ],
            colorized: true)
        }
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
