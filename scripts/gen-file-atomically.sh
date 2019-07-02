#!/bin/sh

# Play it safe.
set -e

##############
# Arguments. #
##############

# The name of the file to generate.
FILE_TO_GENERATE="$1"

# The command that generates the output
# to be written to that file.
COMMAND="$2"

# Create a temporary file.
TEMPFILE=$(mktemp)

# Grab the output of the supplied command.
OUTPUT="$(eval ${COMMAND})"

# Write it into the temporary file.
echo "${OUTPUT}" \
  | perl -pe "s|(.*?)\s*:|\1 ${FILE_TO_GENERATE}:|g" \
  > ${TEMPFILE}

# Grab a lock onto the target directory and 
# (atomically) rename the generated file.
flock "$(dirname "${FILE_TO_GENERATE}")" \
  mv -f ${TEMPFILE} ${FILE_TO_GENERATE}
