# possibly output usage
if [ $HELP ]; then
	echo "Here are some configuration variables you can set to affect how this program is run:"
	echo "DEBUG --- directly runs maude so you can ctrl-c and debug"
	echo "PLAIN --- prints out entire output without filtering it"
	echo "SEARCH --- searches for all possible behaviors instead of interpreting"
	echo "E.g., DEBUG=1 $0"
	echo
	echo "This message was displayed because the variable HELP was set.  Use HELP=0 $0 to turn off"
	exit
fi

# these are compile time settings and are set by the compile script using this file as a template
WRAPPER=EXTERN_WRAPPER
SEARCH_GRAPH_WRAPPER=EXTERN_SEARCH_GRAPH_WRAPPER
IO_SERVER=EXTERN_IO_SERVER
IOFLAG=EXTERN_COMPILED_WITH_IO

# actual start of script
if [ -t 0 ]; then
	stdin=""; 
else
	stdin=$(cat)
fi
username=`id -un`
FSL_C_RUNNER_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`

# create a file consisting of just the maude (the tail of this script)
END_OF_SCRIPT=`sed -n '/-------------------\/------------------/=' $0`
END_OF_SCRIPT=$((END_OF_SCRIPT + 1)) # skip the marking line itself
JUST_MAUDE_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
tail -n+$END_OF_SCRIPT $0 > $JUST_MAUDE_FILE

# now start building up variables that represent ways to run the program
COMMAND_LINE_ARGUMENTS=`for i in $0 "$@"; do echo "String \"$i\"(.List{K}),," ; done`
START_TERM="eval(linked-program, ($COMMAND_LINE_ARGUMENTS .List{K}), \"$stdin\")"

EVAL_LINE="erew in C-program-linked : $START_TERM ."
SEARCH_LINE="search in C-program-linked : $START_TERM =>! B:Bag ."$'\n'
SEARCH_LINE+="show search graph ."

echo > $FSL_C_RUNNER_FILE

# first, set up the runner file with the right commands and set any variables
if [ $DEBUG ]; then 
	echo "break select debug ." >> $FSL_C_RUNNER_FILE
	echo "set break on ." >> $FSL_C_RUNNER_FILE
	echo "$EVAL_LINE" >> $FSL_C_RUNNER_FILE
	COLOR_FLAG="-ansi-color"
elif [ $SEARCH ]; then
	echo "$SEARCH_LINE" >> $FSL_C_RUNNER_FILE
	echo "q" >> $FSL_C_RUNNER_FILE
else 
	echo "$EVAL_LINE" >> $FSL_C_RUNNER_FILE
	echo "q" >> $FSL_C_RUNNER_FILE
fi

MAUDE_COMMAND="maude -no-wrap -no-banner $COLOR_FLAG $JUST_MAUDE_FILE $FSL_C_RUNNER_FILE"

# now we can actually run maude on the runner file we built
# maude changes the way it behaves if it detects that it is working inside a pipe, so we have to call it differently depending on what we want
if [ $DEBUG ]; then
	if [ $IOFLAG ]; then
		perl $IO_SERVER &> tmpIOServerOutput.log &
		PERL_SERVER_PID=$!
	fi
	$MAUDE_COMMAND
elif [ $SEARCH ]; then
	SEARCH_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	GRAPH_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	echo "Performing the search..."
	$MAUDE_COMMAND > $SEARCH_OUTPUT_FILE
	echo "Examining the output..."
	cat $SEARCH_OUTPUT_FILE | perl $SEARCH_GRAPH_WRAPPER > $GRAPH_OUTPUT_FILE
	if [ "$?" -eq 0 ]; then
		set -e # start to fail on error
		cp $SEARCH_OUTPUT_FILE tmpSearchResults.txt
		cp $GRAPH_OUTPUT_FILE tmpSearchResults.dot
		echo "Generating the graph..."
		dot -Tps2 $GRAPH_OUTPUT_FILE > $SEARCH_OUTPUT_FILE # reusing temp file
		cp $SEARCH_OUTPUT_FILE tmpSearchResults.ps
		ps2pdf $SEARCH_OUTPUT_FILE tmpSearchResults.pdf
		echo "Done."
		#acroread tmpSearchResults.pdf &
		set +e #stop failing on error
	fi
	rm -f $SEARCH_OUTPUT_FILE
	rm -f $GRAPH_OUTPUT_FILE
else
	if [ $IOFLAG ]; then
		perl $IO_SERVER &> tmpIOServerOutput.log &
		PERL_SERVER_PID=$!
	fi
	$MAUDE_COMMAND | perl $WRAPPER $PLAIN
fi
RETVAL=$?
if [ $IOFLAG ]; then
	#echo "killing $PERL_SERVER_PID"
	kill -s SIGINT $PERL_SERVER_PID &> /dev/null
fi
rm -f $FSL_C_RUNNER_FILE
rm -f $JUST_MAUDE_FILE
exit $RETVAL


# the following line is required to be there, as it is searched for to cut off this script from the maude program
# there is an unescaped / here so the line above matching is looks different
#-------------------/------------------#
