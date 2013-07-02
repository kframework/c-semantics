#!/bin/bash
# ERRORS=
# for f in brokenDynamically/*.c; do
	# gcc -w $f
	# OUTPUT=`valgrind -q --leak-check=no ./a.out 2>&1`
	# if [ -n "$OUTPUT" ]; then
		# ERRORS="$ERRORS\n\n$f\n$OUTPUT"
		# echo `basename $f`
	# fi
# done
# echo -e $ERRORS

ERRORS=
for f in brokenDynamically/*.c; do
	#echo $f
	clang -w -std=c99 -m32 -fcatch-undefined-behavior -fcatch-undefined-nonarith-behavior $f
	OUTPUT=`./a.out 2>&1`
	# echo $OUTPUT
	if [ -n "$OUTPUT" ]; then
		ERRORS="$ERRORS\n\n$f\n$OUTPUT"
		echo `basename $f`
	fi
done
echo -e $ERRORS