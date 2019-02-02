pipeline {
  agent {
    dockerfile {
      additionalBuildArgs '--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
    }
  }
  stages {
    stage("Init title") {
      when { changeRequest() }
      steps {
        script {
          currentBuild.displayName = "PR ${env.CHANGE_ID}: ${env.CHANGE_TITLE}"
        }
      }
    }
    stage('Build and Test') {
      parallel {
        stage('Build and test open source semantics') {
          steps {
            ansiColor('xterm') {
              sh '''
                eval $(opam config env)
                cd .build/k
                mvn verify -U -Dcheckstyle.skip -DskipKTest -Dllvm.backend.skip -Dhaskell.backend.skip -DbuildProfile=x86_64-gcc-glibc
                cd ../..
                make os-check -j`nproc`
              '''
            }
          }
        }
        stage('RV-Match integration') {
          steps {
            dir('rv-match-build-integration') {
              git credentialsId: 'rv-jenkins', url: 'git@github.com:runtimeverification/rv-match.git', branch: 'master'
              ansiColor('xterm') {
                sh '''
                  eval $(opam config env)
                  git submodule update --init --recursive
                  cd c-semantics
                  git fetch ../../
                  git checkout FETCH_HEAD
                  cd ../
                  mvn verify -U -Dcheckstyle.skip -DskipKTest -Dllvm.backend.skip -Dhaskell.backend.skip -DbuildProfile=x86_64-gcc-glibc
                '''
              }
            }
          }
        }
      }
    }
  }
}
