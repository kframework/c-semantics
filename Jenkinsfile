pipeline {
  agent { label 'docker' }
  stages {
    stage("Init title") {
      when { changeRequest() }
      steps {
        script {
          currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
        }
      }
    }
    stage('Build + Test') {
      when {
        changeRequest()
        beforeAgent true
      }
      agent { dockerfile {
        additionalBuildArgs ''' \
          --build-arg USER_ID=$(id -u) \
          --build-arg GROUP_ID=$(id -g) \
        '''
      } }
      steps { ansiColor('xterm') {
        sh '''
          eval $(opam config env)
          make -j4
          make -C tests/unit-pass -j$(nproc) os-comparison
        '''
      } }
    }
  }
}
