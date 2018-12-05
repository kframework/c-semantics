#!/bin/bash

make "$@" | ./scripts/logger build.log
