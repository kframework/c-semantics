#! /usr/bin/env bash
# assumes the program to be run returns 0 on success
# returns 0 if everything works and finds a bug
# returns 1 if compilation breaks
# returns 2 if runs the program and doesn't detect any errors
# returns 3 if crashes and doesn't detect any errors

set -e

EXPECTED_ARGS=3
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: `basename $0` test_name \"gcc-args\" files"
  exit 1
fi

TOOL_NAME=framac

BASE_NAME=$1
GCC_ARGS=$2
INPUT_FILES=$3

LOG_FILE=logs/$TOOL_NAME/$BASE_NAME.log
mkdir -p logs/$TOOL_NAME
rm -f $LOG_FILE

OUT_DIR=tmp/$TOOL_NAME
OUTPUT_FILE=$OUT_DIR/$BASE_NAME.out
OUT_FILE=$OUT_DIR/$BASE_NAME.o
mkdir -p $OUT_DIR
rm -f $OUT_FILE

set +e
# `frama-c -val -val-signed-overflow-alarms -unspecified-access -slevel 100 -cpp-extra-args="$GCC_ARGS"  $INPUT_FILES > $OUTPUT_FILE 2>&1`
`frama-c -val -obviously-terminates -cpp-extra-args="$GCC_ARGS"  $INPUT_FILES > $OUTPUT_FILE 2>&1`
# -val -val-signed-overflow-alarms -unspecified-access -stop-at-first-alarm -no-val-show-progress -obviously-terminates -precise-unions 

RETVAL=$?
cat $OUTPUT_FILE
if grep -q 'assert' $OUTPUT_FILE; then 
	# if frama-c prints any errors, return 0
	exit 0
elif grep -q 'got status invalid' $OUTPUT_FILE; then 
	# if frama-c prints any errors, return 0
	exit 0
elif [ 0 -eq $RETVAL ]; then
	# if there are no error messages and the return val is 0, the program ran to completion
	exit 2
else
	# if the program returns some other return value (e.g., 139 for segfault) 
	exit 3
fi
set -e
