#!/usr/bin/env perl
use strict;
use File::Spec::Functions qw(rel2abs catfile);
use Getopt::Declare;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
my $THIS_FILE="$0";
my @temporaryFiles = ();

# here we trap control-c (and others) so we can clean up when that happens
$SIG{'ABRT'} = 'interruptHandler';
$SIG{'BREAK'} = 'interruptHandler';
$SIG{'TERM'} = 'interruptHandler';
$SIG{'QUIT'} = 'interruptHandler';
$SIG{'SEGV'} = 'interruptHandler';
$SIG{'HUP' } = 'interruptHandler';
$SIG{'TRAP'} = 'interruptHandler';
$SIG{'STOP'} = 'interruptHandler';
$SIG{'INT'} = 'interruptHandler'; # handle control-c 

sub interruptHandler {
	finalCleanup(); # call single cleanup point
	exit(1); # since we were interrupted, we should exit with a non-zero code
}

# this block gets run at the end of a normally terminating program, whether it simply exits, or dies.  We use this to clean up.
END {
	my $retval = $?; # $? contains the value the program would normally have exited with
	finalCleanup(); # call single cleanup point
	exit($retval);
}

# this subroutine can be used as a way to ensure we clean up all resources whenever we exit.  This is going to be mostly temp files.  If the program terminates for almost any reason, this code will be executed.
sub finalCleanup {
	foreach my $file (@temporaryFiles) {
		unlink ($file);
	}
}
 


if (defined($ENV{'HELP'})) {
	print "Here are some configuration variables you can set to affect how this program is run:\n";
	print "DEBUG --- directly runs maude so you can ctrl-c and debug\n";
	print "PLAIN --- prints out entire output without filtering it\n";
	print "SEARCH --- searches for all possible behaviors instead of interpreting\n";
	print "PROFILE --- performs semantic profiling using this program\n";
	print "GRAPH --- to be used with SEARCH=1; generates a graph of the state space\n";
	print "E.g., DEBUG=1 $THIS_FILE\n";
	print "\n";
	print "This message was displayed because the variable HELP was set.  Use HELP= $THIS_FILE to turn off\n";
	exit(1);
}

# these are compile time settings and are set by the compile script using this file as a template
my $WRAPPER="EXTERN_WRAPPER";
my $SEARCH_GRAPH_WRAPPER="EXTERN_SEARCH_GRAPH_WRAPPER";
my $IO_SERVER="EXTERN_IO_SERVER";
my $IOFLAG="EXTERN_COMPILED_WITH_IO";
my $SCRIPTS_DIR="EXTERN_SCRIPTS_DIR";
my $PROGRAM_NAME="EXTERN_IDENTIFIER";
my $ND_FLAG="EXTERN_ND_FLAG";


my $stdin="";
# actual start of script
if ( -t STDIN ) {
	$stdin=""; 
} else {
	$stdin=join("", <STDIN>);
}
my $username=`id -un`;

my $fileRunner = File::Temp->new( TEMPLATE => 'tmp-kcc-runner-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileRunner);
my $fileStaticInput = File::Temp->new( TEMPLATE => 'tmp-kcc-static-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileStaticInput);
my $fileDynamicInput = File::Temp->new( TEMPLATE => 'tmp-kcc-dynamic-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileDynamicInput);
my $fileDynamicOutput = File::Temp->new( TEMPLATE => 'tmp-kcc-dynamic-out-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileDynamicOutput);

my $fileStaticMaudeDefinition = catfile($SCRIPTS_DIR, 'static-c-total.maude');
my $fileDynamicMaudeDefinition;

if (defined($ENV{'SEARCH'})) {
	$fileDynamicMaudeDefinition = catfile($SCRIPTS_DIR, "c-total-nd.maude");;
} else {
	$fileDynamicMaudeDefinition = catfile($SCRIPTS_DIR, "c-total.maude");
}

# create a file consisting of just the program (the tail of this script)
print $fileStaticInput linkedProgram();


my $commandLineArguments = "";
for my $arg ($THIS_FILE, @ARGV) {	
	$commandLineArguments .= "String \"$arg\"(.List{K}),, ";
}
my $startTerm = "eval(linked-program, ($commandLineArguments .List{K}), \"$stdin\")";

print $fileStaticInput "rew $startTerm .\n";
print $fileStaticInput "q\n";

# EVAL_LINE="erew in C-program-linked : $START_TERM ."
# SEARCH_LINE="search in C-program-linked : $START_TERM =>! B:Bag .
# "
# SEARCH_LINE+="show search graph ."

# echo > $FSL_C_RUNNER_FILE

# # first, set up the runner file with the right commands and set any variables

# if [ $PROFILE ]; then
	# echo "set profile on ." >> $FSL_C_RUNNER_FILE
# fi

# if [ $DEBUG ]; then 
	# echo "break select debug ." >> $FSL_C_RUNNER_FILE
	# echo "set break on ." >> $FSL_C_RUNNER_FILE
	# echo "$EVAL_LINE" >> $FSL_C_RUNNER_FILE
	# COLOR_FLAG="-ansi-color"
# elif [ $SEARCH ]; then
	# echo "$SEARCH_LINE" >> $FSL_C_RUNNER_FILE
# else 
	# echo "$EVAL_LINE" >> $FSL_C_RUNNER_FILE
# fi

# if [ $PROFILE ]; then
	# echo "show profile ." >> $FSL_C_RUNNER_FILE
# fi

# if [ ! $DEBUG ]; then
	print $fileRunner "q\n";
# fi 
# echo $STATIC_MAUDE_DEFINITION
# STATIC_MAUDE_OUTPUT=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
# DYNAMIC_MAUDE_INPUT=`mktemp -t $username-fsl-c.XXXXXXXXXXX`

my $staticMaudeCommand = "maude -no-wrap -no-banner $fileStaticMaudeDefinition " 
	. rel2abs($fileStaticInput)
	. " " . rel2abs($fileRunner);
my $dynamicMaudeCommand = "maude -no-wrap -no-banner $fileDynamicMaudeDefinition $fileDynamicInput $fileRunner";
#print "executing $staticMaudeCommand\n";
my $staticMaudeOutput = `$staticMaudeCommand`;
#print "$staticMaudeOutput\n";
my @staticOutput = split(/\n/, $staticMaudeOutput);
shift(@staticOutput);
shift(@staticOutput);
shift(@staticOutput);
shift(@staticOutput);
pop(@staticOutput);
print $fileDynamicInput "erew (\n";
print $fileDynamicInput join("\n", @staticOutput);
print $fileDynamicInput ") .\n";
print $fileDynamicInput "q\n";
#print "executing dynamic semantics\n";
system("$dynamicMaudeCommand > $fileDynamicOutput") == 0
		or die "Dynamic execution failed: $?";		
#print "executed dynamic semantics\n";
open P, "cat $fileDynamicOutput | perl $WRAPPER |" or die "Error running compiled program!";
my @data=<P>;
close P;
my $returnValue = $? >> 8;
print join("", @data);
exit($returnValue);

# $DYNAMIC_MAUDE_COMMAND | cat - > dynamic-output.txt
# cat dynamic-output.txt | perl $WRAPPER $PLAIN

# # # now we can actually run maude on the runner file we built
# # # maude changes the way it behaves if it detects that it is working inside a pipe, so we have to call it differently depending on what we want
# # if [ $DEBUG ]; then
	# # if [ $IOFLAG ]; then
		# # perl $IO_SERVER &> tmpIOServerOutput.log &
		# # PERL_SERVER_PID=$!
	# # fi
	# # $DYNAMIC_MAUDE_COMMAND
# # elif [ $SEARCH ]; then
	# # #INTERMEDIATE_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	# # #GRAPH_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	# # INTERMEDIATE_OUTPUT_FILE=tmpSearchResults.txt
	# # GRAPH_OUTPUT_FILE=tmpSearchResults.dot
	# # if [ ! 1 = "$ND_FLAG" ]; then
		# # echo "You did not compile this program with the '-n' setting.  You need to recompile this program using '-n' in order to see any non-linear state space."
	# # fi
	# # echo "Performing the search..."
	# # $DYNAMIC_MAUDE_COMMAND > $INTERMEDIATE_OUTPUT_FILE
	# # echo "Generated $INTERMEDIATE_OUTPUT_FILE."
	# # echo "Examining the output..."
	# # cat $INTERMEDIATE_OUTPUT_FILE | perl $SEARCH_GRAPH_WRAPPER $GRAPH_OUTPUT_FILE
	# # echo "Generated $GRAPH_OUTPUT_FILE."
	# # if [ $GRAPH ]; then
# # #		if [ "$?" -eq 0 ]; then
		# # set -e # start to fail on error
		# # echo "Generating the graph..."
		# # dot -Tps2 $GRAPH_OUTPUT_FILE > tmpSearchResults.ps
		# # echo "Generated tmpSearchResults.ps."
		# # ps2pdf tmpSearchResults.ps tmpSearchResults.pdf
		# # echo "Generated tmpSearchResults.pdf."
		# # #acroread tmpSearchResults.pdf &
		# # set +e #stop failing on error
	# # fi
	# # #rm -f $INTERMEDIATE_OUTPUT_FILE
	# # #rm -f $GRAPH_OUTPUT_FILE
# # elif [ $PROFILE ]; then
	# # if [ -f "maudeProfileDBfile.sqlite" ]; then
		# # true
		# # #echo "Database maudeProfileDBfile.sqlite already exists; will add results to it."
	# # else
		# # cp $SCRIPTS_DIR/maudeProfileDBfile.calibration.sqlite maudeProfileDBfile.sqlite
	# # fi
	# # INTERMEDIATE_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	# # #echo "Running the program..."
	# # $DYNAMIC_MAUDE_COMMAND > $INTERMEDIATE_OUTPUT_FILE
	# # cp $INTERMEDIATE_OUTPUT_FILE tmpProfileResults.txt
	# # #echo "Analyzing results..."
	# # cat $INTERMEDIATE_OUTPUT_FILE | perl $WRAPPER $PLAIN
	# # RETVAL=$?
	# # perl $SCRIPTS_DIR/analyzeProfile.pl $INTERMEDIATE_OUTPUT_FILE $PROGRAM_NAME
	# # # cat $INTERMEDIATE_OUTPUT_FILE
	# # # perl $SCRIPTS_DIR/printProfileData.pl -p > tmpProfileResults.csv
	# # #echo "Results added to maudeProfileDBfile.sqlite.  Try running:"
	# # #echo "cat $SCRIPTS_DIR/profile-executiveSummaryByProgram.sql | $SCRIPTS_DIR/accessProfiling.pl"
	# # #echo "See $SCRIPTS_DIR/*.sql for some other example queries."
	# # #echo "Done."
	# # rm -f $INTERMEDIATE_OUTPUT_FILE
	# # exit $RETVAL
# # else
	# # if [ $IOFLAG ]; then
		# # perl $IO_SERVER &> tmpIOServerOutput.log &
		# # PERL_SERVER_PID=$!
	# # fi
	# # $DYNAMIC_MAUDE_COMMAND | perl $WRAPPER $PLAIN
# # fi
# # RETVAL=$?
# # if [ $IOFLAG ]; then
	# # #echo "killing $PERL_SERVER_PID"
	# # kill -s SIGINT $PERL_SERVER_PID &> /dev/null
# # fi
# # rm -f $FSL_C_RUNNER_FILE
# # rm -f $STATIC_MAUDE_INPUT
# exit $RETVAL

# more stuff is added during compilation

