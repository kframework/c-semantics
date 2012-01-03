#! /usr/bin/env bash

set -e

EXPECTED_ARGS=1
if [ $# -ne $EXPECTED_ARGS ]; then
  echo "Usage: `basename $0` file.c"
  exit 1
fi

INPUT_FILE=$1
if [ ! -e $INPUT_FILE ]; then
	echo "$INPUT_FILE does not exist"
	exit 1
fi

LOG_FILE=logs/checkpointer.$INPUT_FILE.log
mkdir -p logs
rm -f $LOG_FILE

OUT_DIR=tmp/$INPUT_FILE
OUTPUT_FILE=$OUT_DIR/$INPUT_FILE.out
mkdir -p $OUT_DIR
rm -f $OUTPUT_FILE


# run checkpointer
/home/software/bin/wine cmd /C "c:\Program Files\SemanticDesigns\DMS\executables\DMSCheckPointer.cmd C~GCC3 -cache ./cache-file -config ./init.h -target $OUT_DIR -source . $INPUT_FILE" >> $LOG_FILE 2>&1 


# convert utf-16 files to utf-8
cp $OUT_DIR/$INPUT_FILE $OUT_DIR/$INPUT_FILE.utf16
iconv -fUTF-16 -tUTF-8 < $OUT_DIR/$INPUT_FILE > $OUT_DIR/$INPUT_FILE.utf8
cp $OUT_DIR/$INPUT_FILE.utf8 $OUT_DIR/$INPUT_FILE

cp $OUT_DIR/check-pointer-data-initializers.c $OUT_DIR/check-pointer-data-initializers.c.utf16
iconv -fUTF-16 -tUTF-8 < $OUT_DIR/check-pointer-data-initializers.c > $OUT_DIR/check-pointer-data-initializers.c.utf8
cp $OUT_DIR/check-pointer-data-initializers.c.utf8 $OUT_DIR/check-pointer-data-initializers.c

cp $OUT_DIR/check-pointer-array-sizes.h $OUT_DIR/check-pointer-array-sizes.h.utf16
iconv -fUTF-16 -tUTF-8 < $OUT_DIR/check-pointer-array-sizes.h > $OUT_DIR/check-pointer-array-sizes.h.utf8
cp $OUT_DIR/check-pointer-array-sizes.h.utf8 $OUT_DIR/check-pointer-array-sizes.h


# compile instrumented code
# have to specify -O or the inlining stuff gets messed up
rm -f ./checkpointer.out
gcc -o checkpointer.out -O -I/home/grosu/celliso2/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer ~/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer/check-pointer.c ~/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer/check-pointer-splay-tree.c ~/.wine/drive_c/Program\ Files/SemanticDesigns/DMS/Domains/C/GCC3/Tools/CheckPointer/check-pointer-wrappers.c $OUT_DIR/*.c >> $LOG_FILE 2>&1 
test -e ./checkpointer.out

./checkpointer.out 2>&1 | tee $OUTPUT_FILE
grep -q '*** Error:' $OUTPUT_FILE

