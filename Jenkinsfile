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
          apt install -y build-essential coreutils diffutils flex git libffi-dev libgmp-dev libmpfr-dev \
                         libstdc++6 libxml2 libz3-dev m4 maven opam openjdk-8-jdk pkg-config python3    \
                         python-jinja2 python-pygments unifdef z3
        '''
      }
    }
    stage('Build and Test') {
      steps {
        ansiColor('xterm') {
          sh '''
            ./.build/k/k-distribution/src/main/scripts/bin/k-configure-opam-dev
            eval $(opam config env)
            cd .build/k
            mvn verify -U -DskipKTest -Dllvm.backend.skip -DbuildProfile=x86_64-gcc-glibc
            cd ../..
            make os-check -j12
          '''
        }
      }
    }
  }
}
