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
          apt-get install -y git build-essential m4 openjdk-8-jdk libgmp-dev libmpfr-dev pkg-config flex z3 libz3-dev maven opam python3
        '''
      }
    }
    stage('Build and Test') {
      steps {
        ansiColor('xterm') {
          sh '''
            ./.build/k/k-distribution/src/main/scripts/bin/k-configure-opam-dev
            eval $(opam config env)
            mvn verify -U -DskipKTest -Dllvm.backend.skip -DbuildProfile=x86_64-gcc-glibc
          '''
        }
      }
    }
  }
}
