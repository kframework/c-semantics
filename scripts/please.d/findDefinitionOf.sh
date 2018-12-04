#!/bin/bash

symbol="$1"
shift

grep "::= $symbol" "$@"
grep "| $symbol" "$@"
