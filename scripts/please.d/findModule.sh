#!/bin/bash

moduleName="$1"
shift

grep "^module $moduleName" "$@"
