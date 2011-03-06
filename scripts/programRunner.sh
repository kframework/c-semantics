# input variables to this script:
# DEBUG
# PLAIN

# these are compile time settings and are set by the compile script using this file as a template
WRAPPER=EXTERN_WRAPPER

# actual start of script
if [ -t 0 ]; then
	stdin=""; 
else
	stdin=$(cat)
fi
username=`id -un`
FSL_C_RUNNER_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
JUST_MAUDE_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`

COMMAND_LINE_ARGUMENTS=`for i in $0 "$@"; do echo "String \"$i\"(.List{K}),," ; done`

EVAL_LINE="erew in C-program-linked : eval(linked-program, ($COMMAND_LINE_ARGUMENTS .List{K}), \"$stdin\") ."

echo > $FSL_C_RUNNER_FILE;

END_OF_SCRIPT=`sed -n '/-------------------\/------------------/=' $0`
END_OF_SCRIPT=$((END_OF_SCRIPT + 1)) # skip the marking line itself

tail -n+$END_OF_SCRIPT $0 > $JUST_MAUDE_FILE

if [ $DEBUG ]; then 
	echo break select debug . >> $FSL_C_RUNNER_FILE
	echo set break on . >> $FSL_C_RUNNER_FILE
	echo $EVAL_LINE >> $FSL_C_RUNNER_FILE
	maude -no-wrap -no-banner $$JUST_MAUDE_FILE $FSL_C_RUNNER_FILE -ansi-color
else 
	echo $EVAL_LINE >> $FSL_C_RUNNER_FILE
	echo q >> $FSL_C_RUNNER_FILE
	maude -no-wrap -no-banner $JUST_MAUDE_FILE $FSL_C_RUNNER_FILE | perl $WRAPPER $PLAIN
fi
retval=$?
rm -f $FSL_C_RUNNER_FILE
rm -f $JUST_MAUDE_FILE
exit $retval


# the following line is required to be there, as it is searched for to cut off this script from the maude program
# there is an unescaped / here so the line above matching is looks different
#-------------------/------------------#
