#!/bin/bash
ERRORS=
for f in brokenDynamically/*.c; do
	gcc -w $f
	OUTPUT=`valgrind -q --leak-check=no ./a.out 2>&1`
	if [ -n "$OUTPUT" ]; then
		ERRORS="$ERRORS\n\n$f\n$OUTPUT"
		echo `basename $f`
	fi
done
echo -e $ERRORS