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
            make ocaml-deps
            eval $(opam config env)
            make -j4
            make -C tests/unit-pass -j$(nproc) os-comparison
          '''
        }
      }
      post {
        always {
          archiveArtifacts artifacts: 'tests/unit-pass/*config', allowEmptyArchive: true
        }
      }
    }
  }
}
