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
        dir('rv-match') {
          git url: 'git@github.com:kframework/rv-match.git'
        }
      }
    }
    stage('Install dependencies') {
      steps {
        sh '''
          apt-get update
          apt install -y bison build-essential clang++-6.0 clang-6.0 cmake coreutils diffutils flex \
                         git libboost-test-dev libffi-dev libgmp-dev libjemalloc-dev libmpfr-dev    \
                         libstdc++6 libxml2 libyaml-cpp-dev libz3-dev llvm-6.0 m4 maven opam        \
                         openjdk-8-jdk pkg-config python3 python-jinja2 python-pygments unifdef     \
                         z3 zlib1g-dev
        '''
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
