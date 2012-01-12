#! /usr/bin/env bash
# assumes the program to be run returns 0 on success
# returns 0 if everything works and valgrind finds a bug
# returns 1 if gcc breaks or valgrind can't run the program
# returns 2 if valgrind runs the program and doesn't detect any errors
# returns 3 if valgrind crashes and doesn't detect any errors

set -e

EXPECTED_ARGS=2
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: `basename $0` test_name \"gcc args\""
  exit 1
fi

TOOL_NAME=valgrind

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

# if gcc fails, return 1
if ! gcc -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99 -o $OUT_FILE $GCC_ARGS >> $LOG_FILE 2>&1; then 
	exit 1
fi

set +e
`valgrind -q --error-exitcode=77 --leak-check=no --undef-value-errors=yes $OUT_FILE > $OUTPUT_FILE 2>&1`
RETVAL=$?
if grep -q 'Invalid read\|Invalid free\|Mismatched free\|Source and destination overlap\|uninitialised' $OUTPUT_FILE; then 
	# if valgrind prints any errors, return 0
	exit 0
elif [ 77 -eq $RETVAL ]; then
	# if there are no error messages but the program returns magical 77, consider it a success
	exit 0
elif [ 0 -eq $RETVAL ]; then
	# if there are no error messages and the return val is 0, the program ran to completion
	exit 2
else
	# if the program returns some other return value (e.g., 139 for segfault) 
	exit 3
fi
set -e
