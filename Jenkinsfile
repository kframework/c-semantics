// Object holding the docker image.
def img

// The dockerhub registry.
def publicRegistry = "runtimeverificationinc/c-semantics"

// Our internal registry.
def privateRegistry = "office.runtimeverification.com:5201/c-semantics"

// Image tag for the private registry.
def IMG_PR_TAG = privateRegistry + ":${env.CHANGE_ID}"

// Image tag for dockerhub.
def IMG_RELEASE_TAG = publicRegistry + ":latest"

pipeline {
  agent none 
  options {
    ansiColor('xterm')
  }
  stages {
    stage ( 'Pull Request' ) {
      agent any
      when { 
        changeRequest()
        beforeAgent true
      }
      options {
        timeout(time: 155, unit: 'MINUTES')
      }
      stages {
        stage ( 'Set title' ) { steps {
          script {
            currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
          }
        } }
        stage ( 'Build docker image' ) { steps {
          sh 'docker pull 10.0.0.21:5201/ubuntu-rv:bionic'
          script {
            img = docker.build "${IMG_PR_TAG}"
          }
        } }
        stage ( 'Push to private registry' ) { steps {
          script {
            img.push()
          }
        } }
        stage ( 'Compile' ) {
          steps {
            script { img.inside {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                export KOMPILE_FLAGS=-O2
                make -j4 profile-rule-parsing --output-sync=line
              '''
            } }
          }
          post { success {
            archiveArtifacts 'dist/timelogs.d/timelogs.csv'
          } }
        }
        stage ( 'Re-compile w/ timeout' ) { steps {
          timeout(time: 8, unit: 'SECONDS' ) {
            script { img.inside {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                make
              '''
            } }
          }
        } }
        stage ( 'Test' ) {
          steps {
            script { img.inside {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                ${K_BIN}/spawn-kserver
                make -C tests/unit-pass -j$(nproc) os-comparison
              '''
            } }
          }
          post { always {
            archiveArtifacts artifacts: 'tests/unit-pass/*config', allowEmptyArchive: true
          } }
        }
        stage ( 'Test clean target' ) { steps {
          script { img.inside {
            sh 'make clean'
            sh '[ $(git clean -xfd 2>&1 | wc -l) -eq 0 ]'
          } }
       } }
      } // stages of 'Pull Request'
    }   // Pull Request

    stage ( 'Merged to master' ) {
      when {
        branch 'master'
        beforeAgent true
      }
      agent any
      stages {
        stage ( 'Build docker image' ) { steps {
          script {
            img = docker.build "${IMG_RELEASE_TAG}"
          }
        } }
        stage ( 'Push to dockerhub' ) { steps {
          script {
            docker.withRegistry( '', 'rvdockerhub' ) {
              sh "docker push ${IMG_RELEASE_TAG}"
            }
          }
        } }
      } // stages of 'Merged to master'
    }   // 'Merged to master'

  }     // pipeline stages
}       // pipeline
