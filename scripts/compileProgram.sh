#!/bin/bash
set -o errexit
PEDANTRY_OPTIONS="-Wall -Wextra -Werror -Wmissing-prototypes -pedantic -x c -std=c99"
GCC_OPTIONS="-CC -std=c99 -nostdlib -nodefaultlibs -U __GNUC__"
myDirectory=`dirname "$0"`
filename=
stateSearch=
function die {
	cleanup
	echo "Something went wrong while compiling the program."
	echo "$1" >&2
	exit $2
}
function cleanup {
	rm -f $compilationLog
}

K_PROGRAM_COMPILE="perl $myDirectory/xmlToK.pl"

set -o nounset
username=`id -un`
compilationLog=`mktemp -t $username-fsl-c-log.XXXXXXXXXXX`
dflag=
nowarn=0
usage="Usage: %s: [-d] inputFileName\n"

while getopts 'mvw' OPTION
do
	case $OPTION in
	m)	stateSearch=1;;
	v)	dflag=1;;
	w)	nowarn=1;;
	?)	die "`printf \"$usage\" $(basename $0)`" 2;;
  esac
done
shift $(($OPTIND - 1))

if [ ! "$1" ]; then
	die "filename expected" 3
fi
trueFilename="$1"
filename=`basename "$1" .c`
escapedFilename=`echo -n $filename | tr "_" "-"`
directoryname=`dirname "$1"`/
if [ ! -e $directoryname$filename.c ]; then
	die "$filename.c not found" 4
fi

# this instead of above
cp $directoryname$filename.c $filename.prepre.gen

set +o errexit
gcc $PEDANTRY_OPTIONS $GCC_OPTIONS -E -iquote "." -iquote "$directoryname" -I "$myDirectory/includes" $filename.prepre.gen > $filename.pre.gen 2> $filename.warnings.log
if [ "$?" -ne 0 ]; then 
	die "Error running preprocessor: `cat $filename.warnings.log`" 6
fi
set -o errexit
if [ ! "$nowarn" ]; then
	cat $filename.warnings.log >&2
fi
#echo "done with gcc"
if [ ! "$dflag" ]; then
	rm -f $filename.prepre.gen
fi
set +o errexit
$myDirectory/cparser $filename.pre.gen --trueName $trueFilename 2> $filename.warnings.log 1> $filename.gen.parse.tmp
if [ "$?" -ne 0 ]; then 
	rm -f $filename.gen.parse.tmp
	msg="Error running C parser: `cat $filename.warnings.log`"
	rm -f $filename.warnings.log
	die "$msg" 7
fi
set -o errexit
if [ ! "$nowarn" ]; then
	cat $filename.warnings.log >&2
fi
if [ ! "$dflag" ]; then
	rm -f $filename.warnings.log
	rm -f $filename.pre.gen
fi
mv $filename.gen.parse.tmp $filename.gen.parse

set +o errexit
cat $filename.gen.parse | $K_PROGRAM_COMPILE 2> $compilationLog 1> program-$filename-compiled.maude
PROGRAMRET=$?
set -o errexit
if [ ! "$dflag" ]; then
	rm -f $filename.gen.parse
fi
if [ "$PROGRAMRET" -ne 0 ]; then
	msg="Error compiling program: `cat $compilationLog`"
	rm -f $compilationLog
	die "$msg" 8
fi

cleanup
