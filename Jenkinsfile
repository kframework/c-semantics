pipeline {
  agent {
    dockerfile {
      additionalBuildArgs ''' \
        --build-arg USER_ID=$(id -u) \
        --build-arg GROUP_ID=$(id -g) \
      '''
    }
  }
  options {
    ansiColor('xterm')
  }
  stages{
    stage("Init title") {
      when { changeRequest() }
      steps {
        script {
          currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
        }
      }
    }
    stage('Build') {
      steps {
        sh '''
          eval "$(opam config env)"
          make -j4
        '''
      }
    }
    stage('Test') {
      steps {
        sh '''
          eval "$(opam config env)"
          make -C tests/unit-pass -j$(nproc) os-comparison
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'tests/unit-pass/*config', allowEmptyArchive: true
        }
      }
    }
  }
}
