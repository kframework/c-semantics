#!/bin/sh

PREFIX="[BUILD LOGGING]"
LINE_MARK="================================================================"


log() {
  echo "${PREFIX} ${LINE_MARK}"
  echo "${PREFIX} $1"
  echo "${PREFIX} ${LINE_MARK}"
}

log "$@"
