#! /usr/bin/env bash

export DMS_OUTPUT_ENCODING=ISO-8859-1
# -DCHECK_POINTER_TERMINATE_ON_ERROR

set -e

EXPECTED_ARGS=2
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: `basename $0` testName \"files.c\""
  exit 1
fi

TOOL_NAME=checkpointer

BASE_NAME=$1
INPUT_FILES=$2

# if [ ! -e $INPUT_FILE ]; then
	# echo "$INPUT_FILE does not exist"
	# exit 1
# fi

LOG_FILE=logs/$TOOL_NAME/$BASE_NAME.log
mkdir -p logs/$TOOL_NAME
rm -f $LOG_FILE

OUT_DIR=tmp/$TOOL_NAME
OUTPUT_FILE=$OUT_DIR/$BASE_NAME.out
OUT_FILE=$OUT_DIR/$BASE_NAME.o
mkdir -p $OUT_DIR
rm -f $OUT_FILE


# run checkpointer
/home/software/bin/wine cmd /C "c:\Program Files\SemanticDesigns\DMS\executables\DMSCheckPointer.cmd C~GCC3 -cache ./cache-file -config ./init.h -target $OUT_DIR -source . $INPUT_FILES" >> $LOG_FILE 2>&1 


# convert utf-16 files to utf-8
# cp $OUT_DIR/$INPUT_FILE $OUT_DIR/$INPUT_FILE.utf16
# iconv -fUTF-16 -tUTF-8 < $OUT_DIR/$INPUT_FILE > $OUT_DIR/$INPUT_FILE.utf8
# cp $OUT_DIR/$INPUT_FILE.utf8 $OUT_DIR/$INPUT_FILE

# cp $OUT_DIR/check-pointer-data-initializers.c $OUT_DIR/check-pointer-data-initializers.c.utf16
# iconv -fUTF-16 -tUTF-8 < $OUT_DIR/check-pointer-data-initializers.c > $OUT_DIR/check-pointer-data-initializers.c.utf8
# cp $OUT_DIR/check-pointer-data-initializers.c.utf8 $OUT_DIR/check-pointer-data-initializers.c

# cp $OUT_DIR/check-pointer-array-sizes.h $OUT_DIR/check-pointer-array-sizes.h.utf16
# iconv -fUTF-16 -tUTF-8 < $OUT_DIR/check-pointer-array-sizes.h > $OUT_DIR/check-pointer-array-sizes.h.utf8
# cp $OUT_DIR/check-pointer-array-sizes.h.utf8 $OUT_DIR/check-pointer-array-sizes.h


# compile instrumented code
# have to specify -O or the inlining stuff gets messed up
rm -f ./checkpointer.out
gcc -o $OUT_FILE -O -I/home/grosu/celliso2/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer ~/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer/check-pointer.c ~/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer/check-pointer-splay-tree.c ~/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer/check-pointer-wrappers.c $OUT_DIR/*.c >> $LOG_FILE 2>&1 
test -e $OUT_FILE

set +e
`$OUT_FILE > $OUTPUT_FILE 2>&1`
RETVAL=$?
if grep -q '*** Error:' $OUTPUT_FILE; then 
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
