# possibly output usage
if [ $HELP ]; then
	echo "Here are some configuration variables you can set to affect how this program is run:"
	echo "DEBUG --- directly runs maude so you can ctrl-c and debug"
	echo "PLAIN --- prints out entire output without filtering it"
	echo "SEARCH --- searches for all possible behaviors instead of interpreting"
	echo "PROFILE --- performs semantic profiling using this program"
	echo "GRAPH --- to be used with SEARCH=1; generates a graph of the state space"
	echo "E.g., DEBUG=1 $0"
	echo
	echo "This message was displayed because the variable HELP was set.  Use HELP= $0 to turn off"
	exit
fi

THIS_FILE="$0"

# these are compile time settings and are set by the compile script using this file as a template
WRAPPER=EXTERN_WRAPPER
SEARCH_GRAPH_WRAPPER=EXTERN_SEARCH_GRAPH_WRAPPER
IO_SERVER=EXTERN_IO_SERVER
IOFLAG=EXTERN_COMPILED_WITH_IO
SCRIPTS_DIR=EXTERN_SCRIPTS_DIR
PROGRAM_NAME=EXTERN_IDENTIFIER
ND_FLAG=EXTERN_ND_FLAG

# actual start of script
if [ -t 0 ]; then
	stdin=""; 
else
	stdin=$(cat)
fi
username=`id -un`
FSL_C_RUNNER_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`

# create a file consisting of just the maude (the tail of this script)
END_OF_SCRIPT=`sed -n '/-------------------\/------------------/=' $THIS_FILE`
END_OF_SCRIPT=$((END_OF_SCRIPT + 1)) # skip the marking line itself
JUST_MAUDE_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
tail -n+$END_OF_SCRIPT $THIS_FILE > $JUST_MAUDE_FILE
if [ $PROFILE_CALIBRATION ]; then
	THIS_FILE="" # for the calibration, we want the filename to be as short as possible
fi
# now start building up variables that represent ways to run the program
COMMAND_LINE_ARGUMENTS=`for i in $THIS_FILE "$@"; do echo "String \"$i\"(.List{K}),," ; done`
START_TERM="eval(linked-program, ($COMMAND_LINE_ARGUMENTS .List{K}), \"$stdin\")"

EVAL_LINE="erew in C-program-linked : $START_TERM ."
SEARCH_LINE="search in C-program-linked : $START_TERM =>! B:Bag ."$'\n'
SEARCH_LINE+="show search graph ."

echo > $FSL_C_RUNNER_FILE

# first, set up the runner file with the right commands and set any variables

if [ $PROFILE ]; then
	echo "set profile on ." >> $FSL_C_RUNNER_FILE
fi

if [ $DEBUG ]; then 
	echo "break select debug ." >> $FSL_C_RUNNER_FILE
	echo "set break on ." >> $FSL_C_RUNNER_FILE
	echo "$EVAL_LINE" >> $FSL_C_RUNNER_FILE
	COLOR_FLAG="-ansi-color"
elif [ $SEARCH ]; then
	echo "$SEARCH_LINE" >> $FSL_C_RUNNER_FILE
else 
	echo "$EVAL_LINE" >> $FSL_C_RUNNER_FILE
fi

if [ $PROFILE ]; then
	echo "show profile ." >> $FSL_C_RUNNER_FILE
fi

if [ ! $DEBUG ]; then
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
	#INTERMEDIATE_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	#GRAPH_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	INTERMEDIATE_OUTPUT_FILE=tmpSearchResults.txt
	GRAPH_OUTPUT_FILE=tmpSearchResults.dot
	if [ ! 1 = "$ND_FLAG" ]; then
		echo "You did not compile this program with the '-n' setting.  You need to recompile this program using '-n' in order to see any non-linear state space."
	fi
	echo "Performing the search..."
	$MAUDE_COMMAND > $INTERMEDIATE_OUTPUT_FILE
	echo "Generated $INTERMEDIATE_OUTPUT_FILE."
	echo "Examining the output..."
	cat $INTERMEDIATE_OUTPUT_FILE | perl $SEARCH_GRAPH_WRAPPER $GRAPH_OUTPUT_FILE
	echo "Generated $GRAPH_OUTPUT_FILE."
	if [ $GRAPH ]; then
#		if [ "$?" -eq 0 ]; then
		set -e # start to fail on error
		echo "Generating the graph..."
		dot -Tps2 $GRAPH_OUTPUT_FILE > tmpSearchResults.ps
		echo "Generated tmpSearchResults.ps."
		ps2pdf tmpSearchResults.ps tmpSearchResults.pdf
		echo "Generated tmpSearchResults.pdf."
		#acroread tmpSearchResults.pdf &
		set +e #stop failing on error
	fi
	#rm -f $INTERMEDIATE_OUTPUT_FILE
	#rm -f $GRAPH_OUTPUT_FILE
elif [ $PROFILE ]; then
	if [ -f "maudeProfileDBfile.sqlite" ]; then
		true
		#echo "Database maudeProfileDBfile.sqlite already exists; will add results to it."
	else
		cp $SCRIPTS_DIR/maudeProfileDBfile.calibration.sqlite maudeProfileDBfile.sqlite
	fi
	INTERMEDIATE_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	#echo "Running the program..."
	$MAUDE_COMMAND > $INTERMEDIATE_OUTPUT_FILE
	cp $INTERMEDIATE_OUTPUT_FILE tmpProfileResults.txt
	#echo "Analyzing results..."
	cat $INTERMEDIATE_OUTPUT_FILE | perl $WRAPPER $PLAIN
	RETVAL=$?
	perl $SCRIPTS_DIR/analyzeProfile.pl $INTERMEDIATE_OUTPUT_FILE $PROGRAM_NAME
	# cat $INTERMEDIATE_OUTPUT_FILE
	# perl $SCRIPTS_DIR/printProfileData.pl -p > tmpProfileResults.csv
	#echo "Results added to maudeProfileDBfile.sqlite.  Try running:"
	#echo "cat $SCRIPTS_DIR/profile-executiveSummaryByProgram.sql | $SCRIPTS_DIR/accessProfiling.pl"
	#echo "See $SCRIPTS_DIR/*.sql for some other example queries."
	#echo "Done."
	rm -f $INTERMEDIATE_OUTPUT_FILE
	exit $RETVAL
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
