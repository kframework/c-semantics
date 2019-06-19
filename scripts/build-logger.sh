#!/bin/sh

PREFIX="[BUILD LOGGING]"

log() {
  echo "${PREFIX} $1"
}


log "************************************* BEGIN BUILD LOGGING ************************************"
log "$@"
log "************************************** END BUILD LOGGING *************************************"
