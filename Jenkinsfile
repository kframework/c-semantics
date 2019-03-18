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
  }
}
