#! /usr/bin/env bash
# assumes the program to be run returns 0 on success
# returns 0 if everything works and finds a bug
# returns 1 if compilation breaks
# returns 2 if runs the program and doesn't detect any errors
# returns 3 if crashes and doesn't detect any errors

set -e

EXPECTED_ARGS=2
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: `basename $0` test_name \"args\""
  exit 1
fi

TOOL_NAME=ubc

BASE_NAME=$1
GCC_ARGS=$2

LOG_FILE=logs/$TOOL_NAME/$BASE_NAME.log
mkdir -p logs/$TOOL_NAME
rm -f $LOG_FILE

OUT_DIR=tmp/$TOOL_NAME
OUTPUT_FILE=$OUT_DIR/$BASE_NAME.out
OUT_FILE=$OUT_DIR/$BASE_NAME.o
mkdir -p $OUT_DIR
rm -f $OUT_FILE

# if tool fails, return 1
if ! clang -o $OUT_FILE -fcatch-undefined-c99-behavior -fcatch-undefined-nonarith-behavior $GCC_ARGS >> $LOG_FILE 2>&1; then
	exit 1
fi

set +e
`$OUT_FILE > $OUTPUT_FILE 2>&1`
RETVAL=$?
if grep -q '^CLANG ' $OUTPUT_FILE; then 
	# if tool prints any errors, return 0
	exit 0
elif [ 0 -eq $RETVAL ]; then
	# if there are no error messages and the return val is 0, the program ran to completion
	exit 2
else
	# if the program returns some other return value (e.g., 139 for segfault) 
	exit 3
fi
set -e
