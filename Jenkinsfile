pipeline {
  agent none
  stages {
    stage ( 'Attempt' ) {
      when {
        changeRequest()
        beforeAgent true
      }
      agent {
        dockerfile {
          args '--name mycont'
          additionalBuildArgs '--tag mytag'
          reuseNode true
        }
      }
      steps {
        sh 'echo foo'
      }
    }
    stage ( 'D' ) {
      when {
        changeRequest()
        beforeAgent true
      }
      agent any
      steps {
        sh 'docker image ls'
        sh 'docker container ls'
      }
    }
  }
}
