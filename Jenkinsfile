// Object holding the docker image.
def img

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
      stages {
        stage ( 'Set title' ) { steps {
          script {
            currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
          }
        } }
        stage ( 'Build docker image' ) { steps {
          script {
            def uid = sh([returnStdout: true, script: 'id -u']).trim()
            def gid = sh([returnStdout: true, script: 'id -g']).trim()
            img = docker.build("c-semantics:${env.CHANGE_ID}", "--build-arg=USER_ID=${uid} --build-arg=GROUP_ID=${gid} .")
          }
        } }
        stage ( 'Compile' ) {
          options {
            timeout(time: 70, unit: 'MINUTES')
          }
          steps {
            script { img.inside {
              sh '''
                eval $(opam config env)
                eval $(perl -I "~/perl5/lib/perl5" -Mlocal::lib)
                export KOMPILE_FLAGS=-O1
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
          options {
            timeout(time: 300, unit: 'MINUTES')
          }
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
            img = docker.build 'runtimeverificationinc/c-semantics:latest'
          }
        } }
      } // stages of 'Merged to master'
    }   // 'Merged to master'

  }     // pipeline stages
}       // pipeline
