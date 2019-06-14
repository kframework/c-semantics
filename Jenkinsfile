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
          eval $(opam config env)
          export KOMPILE_FLAGS=-O2
          make -j4 profile-rule-parsing
        '''
      }
      post { success {
        archiveArtifacts artifacts: 'dist/timelogs.d/timelogs.csv'
      } }
    }
    stage('Re-Build with timeout') { steps {
      timeout(time: 8, unit: 'SECONDS') {
        sh '''
          eval $(opam config env)
          make
        '''
      }
    } }
    stage('Test') {
      steps {
        sh '''
          eval $(opam config env)
          make -C tests/unit-pass -j$(nproc) os-comparison
        '''
      }
      post {
        always {
          archiveArtifacts artifacts: 'tests/unit-pass/*config', allowEmptyArchive: true
        }
      }
    }
    stage('Test clean target') { steps {
      sh 'make clean'
      sh '[ $(git clean -xfd 2>&1 | wc -l) -eq 0 ]'
    } }
  }
}
