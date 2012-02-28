set -e
# OUT_DIR=finalgood
# rm -rf $OUT_DIR
# mkdir -p $OUT_DIR

# GCC_ARGS="-I testcasesupport -DINCLUDEMAIN -E -P"

# for dir in good/*
# do
	# for file in $dir/*.c
	# do
		# filename=`basename $file`
		# gcc $GCC_ARGS -DOMITBAD $file > $OUT_DIR/$filename
	# done
# done


# OUT_DIR=finalbad
# rm -rf $OUT_DIR
# mkdir -p $OUT_DIR

# for dir in good/*
# do
	# for file in $dir/*.c
	# do
		# filename=`basename $file`
		# gcc $GCC_ARGS -DOMITGOOD $file > $OUT_DIR/$filename
	# done
# done


OUT_DIR=finalpre
rm -rf $OUT_DIR

top=2
count=$(($top+1))
for i in $(seq 0 $top)
do
	echo $i
	mkdir -p "$OUT_DIR/$i"
done
i=$top
for dir in good/*
do
	for file in $dir/*.c
	do
		# filename=`basename $file`
		BASEFILE=$(echo $file | sed 's/\([1-9][0-9]\?\)[a-z]\?\.c/\1/')
		i=$((($i + 1) % $count))
		set +e
		mv -f $BASEFILE* $OUT_DIR/$i/ 2> /dev/null
		set -e

	done
done
