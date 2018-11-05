#!/bin/bash

# Configuration settings for K and c-semantics

#################
# System settings
#################

# Where to put dependencies
SW_DIR="$HOME/sw"
K_PATH="$SW_DIR/k"
CLANG_PATH="$SW_DIR/clang-$CLANG_VERSION"


################
# Clang settings
################

CLANG_VERSION="3.9.1"

#############
# K Framework
#############

# When the support for opam-2 gets merged,
# we will use the master branch of the official
# repository
# K_REPO="https://github.com/kframework/k.git"
# K_BRANCH="master"
# Until than we have to use the patched version:
K_REPO="https://github.com/h0nzZik/k5.git"
K_BRANCH="both-opam-1-2-workaround"

# This should stay the same
K_BIN="$SW_DIR/k/k-distribution/bin"


#################
# C/C++ semantics
#################

C_SEMANTICS_REPO="https://github.com/kframework/c-semantics.git"
C_SEMANTICS_BRANCH="master"

# The main subdirectory in the C_SEMANTICS_REPO.
# For RV-Match, this should be "c-semantics/"
C_SEMANTICS_SUBDIRECTORY="./"



