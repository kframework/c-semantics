pipeline {
  agent {
    docker {
      image 'ubuntu:bionic'
      args '-u 0'
    }
  }
  options {
    skipDefaultCheckout true
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
    stage('Checkout code') {
      steps {
        sh 'rm -rf ./*'
        checkout scm
      }
    }
    stage('Install dependencies') {
      steps {
        sh '''
          apt-get update
          apt-get install -y git cmake clang-6.0 zlib1g-dev bison flex libboost-test-dev libgmp-dev libmpfr-dev libyaml-cpp-dev libjemalloc-dev curl
          curl https://sh.rustup.rs -sSf | sh -s -- -y
          . $HOME/.cargo/env
          rustup toolchain install 1.28.0
          rustup default 1.28.0
          curl -sSL https://get.haskellstack.org/ | sh
          mkdir -p ~/.stack
          echo 'allow-different-user: true' > ~/.stack/config.yaml
        '''
      }
    }
    stage('Build and Test') {
      steps {
        ansiColor('xterm') {
          sh '''
            make os-check -j12
          '''
        }
      }
    }
  }
}
