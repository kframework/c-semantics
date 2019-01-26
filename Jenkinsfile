pipeline {
  agent {
    dockerfile {
      additionalBuildArgs '--build-arg USER_ID=$(id -u) --build-arg GROUP_ID=$(id -g)'
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
        dir('rv-match') {
          git url: 'git@github.com:kframework/rv-match.git'
        }
      }
    }
    stage('Build and Test') {
      steps {
        ansiColor('xterm') {
          sh '''
            cpan install App::FatPacker Getopt::Declare String::Escape String::ShellQuote UUID::Tiny
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
    stage('RV-Match Integration') {
      steps {
        ansiColor('xterm') {
          sh '''
            cd rv-match
            git submodule update --init
            cd c-semantics
            git fetch ../../
            git checkout FETCH_HEAD
            cd ../
            mvn verify -U -DskipKTest -DbuildProfile=x86_64-gcc-glibc
          '''
        }
      }
    }
  }
}
