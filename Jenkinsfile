pipeline {
  agent {
    dockerfile {
      label 'docker'
      additionalBuildArgs '--build-arg K_COMMIT=$(cd ext/k && git rev-parse --short=7 HEAD) --build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
    }
  }
  options { ansiColor('xterm') }
  stages {
    stage('Pull Request') {
      when { 
        changeRequest()
        beforeAgent true
      }
      stages {
        stage('Set title') { steps { script { currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}" } } }
        stage('Compile') {
          options { timeout(time: 70, unit: 'MINUTES') }
          steps {
            script {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                export KOMPILE_FLAGS=-O2
                make -j4 profile-rule-parsing --output-sync=line
              '''
            }
          }
          post { success { archiveArtifacts 'dist/timelogs.d/timelogs.csv' } }
        }
        stage('Re-compile w/ timeout') {
          options { timeout(time: 8, unit: 'MINUTES') }
          steps {
            script {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                make
              '''
            }
          }
        }
        stage('Test') {
          options { timeout(time: 300, unit: 'MINUTES') }
          steps {
            script {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                ${K_BIN}/spawn-kserver
                make -C tests/unit-pass -j$(nproc) os-comparison
              '''
            }
          }
          post { always { archiveArtifacts artifacts: 'tests/unit-pass/*config', allowEmptyArchive: true } }
        }
        stage('Test clean target') {
          steps {
            script {
              sh 'make clean'
              sh '[ $(git clean -xfd 2>&1 | wc -l) -eq 0 ]'
            }
          }
        }
      }
    }
  }
}
