set -e

OUT_DIR=finalgood
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

GCC_ARGS="-I testcasesupport -DINCLUDEMAIN -E -P"

for dir in good/*
do
	for file in $dir/*.c
	do
		filename=`basename $file`
		gcc $GCC_ARGS -DOMITBAD $file > $OUT_DIR/$filename
	done
done


OUT_DIR=finalbad
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

for dir in good/*
do
	for file in $dir/*.c
	do
		filename=`basename $file`
		gcc $GCC_ARGS -DOMITGOOD $file > $OUT_DIR/$filename
	done
done


OUT_DIR=finalpre
rm -rf $OUT_DIR
mkdir -p $OUT_DIR

for dir in good/*
do
	for file in $dir/*.c
	do
		filename=`basename $file`
		cp $file $OUT_DIR/$filename
	done
done
