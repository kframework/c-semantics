#!/bin/bash
# Prepares environment for K and c-semantics

source settings.sh

eval `opam config env`

export PATH="$K_BIN:$PATH"


