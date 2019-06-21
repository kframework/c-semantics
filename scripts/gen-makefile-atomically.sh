#!/bin/sh

# Play it safe.
set -e

# Arguments.
K_OUTPUT_DIR="$1"
K_SOURCE_FILE="$2"
MAKEFILE_TO_GENERATE="$3"
KDEP="$4"
KDEP_FLAGS="$5"

# Create a temporary file.
TEMPFILE=$(mktemp)

# Grab the output of kdep.
KDEP_OUTPUT="$( \
  "${KDEP}" ${KDEP_FLAGS} -d "${K_OUTPUT_DIR}" -- "${K_SOURCE_FILE}" \
)"

# Write it into the temporary file.
echo "${KDEP_OUTPUT}" \
  | perl -pe "s|(.*?)\s*:|\1 ${MAKEFILE_TO_GENERATE}:|g" \
  > ${TEMPFILE}

# The directory in which the generated makefile will reside.
MAKEFILE_DIR="$(dirname "${MAKEFILE_TO_GENERATE}")"

# Atomically rename the generated makefile.
flock "${MAKEFILE_DIR}" mv -f ${TEMPFILE} ${MAKEFILE_TO_GENERATE}
