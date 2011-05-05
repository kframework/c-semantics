#!/usr/bin/env perl
use strict;
use File::Spec::Functions qw(rel2abs catfile);
use Getopt::Declare;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
my $thisFile = "$0";
my @temporaryFiles = ();
my $PERL_SERVER_PID = 0;


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
		close($file);
		unlink ($file);
	}
	if ($PERL_SERVER_PID > 0) {
		my $ret = kill(2, $PERL_SERVER_PID);
	}
}
 


if (defined($ENV{'HELP'})) {
	print "Here are some configuration variables you can set to affect how this program is run:\n";
	print "DEBUG --- directly runs maude so you can ctrl-c and debug\n";
	print "DEBUG_STATIC --- directly runs static semantics in maude so you can ctrl-c and debug\n";
	print "PLAIN --- prints out entire output without filtering it\n";
	print "SEARCH --- searches for all possible behaviors instead of interpreting\n";
	print "PROFILE --- performs semantic profiling using this program\n";
	print "GRAPH --- to be used with SEARCH=1; generates a graph of the state space\n";
	print "E.g., DEBUG=1 $thisFile\n";
	print "\n";
	print "This message was displayed because the variable HELP was set.  Use HELP= $thisFile to turn off\n";
	exit(1);
}

# these are compile time settings and are set by the compile script using this file as a template
my $IO_SERVER="EXTERN_IO_SERVER";
my $IOFLAG="EXTERN_COMPILED_WITH_IO";
my $SCRIPTS_DIR="EXTERN_SCRIPTS_DIR";
my $PROGRAM_NAME="EXTERN_IDENTIFIER";
my $ND_FLAG="EXTERN_ND_FLAG";

my $wrapperScript = catfile($SCRIPTS_DIR, 'wrapper.pl');
require $wrapperScript;
my $graphScript = catfile($SCRIPTS_DIR, 'graphSearch.pl');
require $graphScript;

my $stdin="";
# actual start of script
if ( -t STDIN ) {
	$stdin=""; 
} else {
	$stdin=join("", <STDIN>);
}
my $username=`id -un`;

my $fileStaticRunner = File::Temp->new( TEMPLATE => 'tmp-kcc-runner-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileStaticRunner);
my $fileDynamicRunner = File::Temp->new( TEMPLATE => 'tmp-kcc-runner-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
#open my $fileDynamicRunner, ">fileDynamicRunner.maude";
push(@temporaryFiles, $fileDynamicRunner);
my $fileStaticInput = File::Temp->new( TEMPLATE => 'tmp-kcc-static-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileStaticInput);
# my $fileDynamicInput = File::Temp->new( TEMPLATE => 'tmp-kcc-dynamic-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
# push(@temporaryFiles, $fileDynamicInput);

my $fileStaticMaudeDefinition = catfile($SCRIPTS_DIR, 'static-c-total.maude');
my $fileDynamicMaudeDefinition;

if (defined($ENV{'SEARCH'})) {
	$fileDynamicMaudeDefinition = catfile($SCRIPTS_DIR, "c-total-nd.maude");
} else {
	$fileDynamicMaudeDefinition = catfile($SCRIPTS_DIR, "c-total.maude");
}

# create a file consisting of just the program (the tail of this script)
print $fileStaticInput linkedProgram();

my $commandLineArguments = "";
for my $arg ($thisFile, @ARGV) {	
	$commandLineArguments .= "String \"$arg\"(.List{K}),, ";
}
my $startTerm = "eval(linked-program, ($commandLineArguments .List{K}), \"$stdin\")";

# print $fileStaticInput "rew $startTerm .\n";
# print $fileStaticInput "q\n";

my $evalLine = "rew in C-program-linked : $startTerm .";


# first, set up the runner file with the right commands and set any variables

if (defined($ENV{'PROFILE'})) {
	print $fileStaticRunner "set profile on .\n";
	print $fileDynamicRunner "set profile on .\n";
}

if (defined($ENV{'STATIC_DEBUG'})) {
	print $fileStaticRunner "break select debug .\n";
	print $fileStaticRunner "set break on .\n";
}
if (defined($ENV{'DEBUG'})) {
	#print "Debugging\n";
	print $fileDynamicRunner "break select debug .\n";
	print $fileDynamicRunner "set break on .\n";
}
print $fileStaticRunner "$evalLine\n";

# if (defined($ENV{'PROFILE'})) {
	# print $fileStaticRunner "show profile .\n";
# }
if (! defined($ENV{'STATIC_DEBUG'})) {
	print $fileStaticRunner "q\n";
}

# I had to add this strange true; thing to get it to work in windows.  no idea why...
my $staticMaudeCommand = "true; maude -no-wrap -no-banner $fileStaticMaudeDefinition " 
	. rel2abs($fileStaticInput)
	. " " . rel2abs($fileStaticRunner);

if (defined($ENV{'STATIC_DEBUG'})) {
	exit runDebugger($staticMaudeCommand);
}
# here, we know we're not debugging the static semantics
# print "Running static stuff\n";
# print "Running $staticMaudeCommand\n";
close($fileStaticInput);
close($fileStaticRunner);

my $staticMaudeOutput = `$staticMaudeCommand`;
# print "finished running static stuff\n";
my $dynamicInput = processStaticOutput($staticMaudeOutput);
my $dynamicMaudeCommand = "true; maude -no-wrap -no-banner $fileDynamicMaudeDefinition $fileDynamicRunner";
#print $fileDynamicRunner "mod C-program-linked is including C .\n";
#print $fileDynamicRunner "op linked-program : -> K .\n";
#print $fileDynamicRunner "eq linked-program = ($dynamicInput) .\n";
#print $fileDynamicRunner "endm\n";
if (defined($ENV{'SEARCH'})) {
	print $fileDynamicRunner "search $dynamicInput =>! B:Bag .\n";
	print $fileDynamicRunner "show search graph .\n"
} else {
	print $fileDynamicRunner "erew $dynamicInput .\n";
}
if (defined($ENV{'PROFILE'})) {
	print $fileDynamicRunner "show profile .\n";
}
if (! defined($ENV{'DEBUG'})) {
	print $fileDynamicRunner "q\n";
}

# now we can actually run maude on the runner file we built
# maude changes the way it behaves if it detects that it is working inside a pipe, so we have to call it differently depending on what we want
close($fileDynamicRunner);
if (defined($ENV{'DEBUG'})) {
	#io
	exit runDebugger($dynamicMaudeCommand);
} elsif (defined($ENV{'SEARCH'})) {
	my $intermediateOutputFile = "tmpSearchResults.txt";
	my $graphOutputFile = "tmpSearchResults.dot";
	if ($ND_FLAG) {
		print "You did not compile this program with the '-n' setting.  You need to recompile this program using '-n' in order to see any non-linear state space.\n";
	}
	print "Performing the search...\n";
	my ($returnValue, @dynamicOutput) = runProgram($dynamicMaudeCommand);
	open(my $fh, ">$intermediateOutputFile");
	print $fh join("", @dynamicOutput);
	close($fh);
	print "Generated $intermediateOutputFile\n";
	print "Examining the output...\n";
	my $graphOutput = graphSearch($graphOutputFile, @dynamicOutput);
	print "$graphOutput\n";
	print "Generated $graphOutputFile.\n";
	
	if (defined($ENV{'GRAPH'})) {
		print "Generating graph...\n";
		system("dot -Tps2 $graphOutputFile > tmpSearchResults.ps") == 0 or die "Running dot failed: $?";
		print "Generated tmpSearchResults.ps.\n";
		system("ps2pdf tmpSearchResults.ps tmpSearchResults.pdf") == 0 or die "Running ps2pdf failed: $?";
		print "Generated tmpSearchResults.pdf\n";
	}
} elsif (defined($ENV{'PROFILE'})) {

	if (! -e "maudeProfileDBfile.sqlite") {
		copy(catfile($SCRIPTS_DIR, "maudeProfileDBfile.calibration.sqlite"), "maudeProfileDBfile.sqlite");
	}
	my $intermediateOutputFile = File::Temp->new( TEMPLATE => 'tmp-kcc-intermediate-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
	push(@temporaryFiles, $intermediateOutputFile);
	
	my ($returnValue) = runProgram("$dynamicMaudeCommand > $intermediateOutputFile");
	if ($returnValue != 0) {
		die "Dynamic execution failed: $returnValue";
	}	
	copy($intermediateOutputFile, "tmpProfileResults.txt");
	open (my $fh, "<$intermediateOutputFile");
	my @dynamicOutput = <$fh>;
	close($fh);
	my ($finalReturnValue, $finalOutput) = maudeOutputWrapper(defined($ENV{'PLAIN'}), @dynamicOutput);
	print $finalOutput;
	my $profileWrapper = catfile($SCRIPTS_DIR, 'analyzeProfile.pl');
	`perl $profileWrapper $intermediateOutputFile $PROGRAM_NAME`;
	exit($finalReturnValue);
} else {

	if ($IOFLAG) {
		$PERL_SERVER_PID = fork();
		die "unable to fork: $!" unless defined($PERL_SERVER_PID);
		if (!$PERL_SERVER_PID) {  # child
			exec("perl $IO_SERVER &> tmpIOServerOutput.log");
			die "unable to exec: $!";
		}
	}
	# if [ $IOFLAG ]; then
		# perl $IO_SERVER &> tmpIOServerOutput.log &
		# PERL_SERVER_PID=$!
	# fi
	#print "going to run dynamic stuff\n";
	my ($returnValue, @dynamicOutput) = runProgram($dynamicMaudeCommand);
	#print "finished running dynamic stuff\n";
	if ($returnValue != 0) {
		die "Dynamic execution failed: $returnValue";
	}	
	my ($finalReturnValue, $finalOutput) = maudeOutputWrapper(defined($ENV{'PLAIN'}), @dynamicOutput);
	print $finalOutput;
	exit($finalReturnValue);
}

# runs a command and returns a pair (return value, output)
sub runProgram {
	my ($command) = (@_);
	open P, "$command |" or die "Error running \"$command\"!";
	my @data=<P>;
	close P;
	my $returnValue = $? >> 8;
	
	return ($returnValue, @data);
}


# if [ $DEBUG ]; then
	# # if [ $IOFLAG ]; then
		# # perl $IO_SERVER &> tmpIOServerOutput.log &
		# # PERL_SERVER_PID=$!
	# # fi
	# $DYNAMIC_MAUDE_COMMAND
# elif [ $SEARCH ]; then
	# #INTERMEDIATE_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	# #GRAPH_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	# INTERMEDIATE_OUTPUT_FILE=tmpSearchResults.txt
	# GRAPH_OUTPUT_FILE=tmpSearchResults.dot
	# if [ ! 1 = "$ND_FLAG" ]; then
		# echo "You did not compile this program with the '-n' setting.  You need to recompile this program using '-n' in order to see any non-linear state space."
	# fi
	# echo "Performing the search..."
	# $DYNAMIC_MAUDE_COMMAND > $INTERMEDIATE_OUTPUT_FILE
	# echo "Generated $INTERMEDIATE_OUTPUT_FILE."
	# echo "Examining the output..."
	# cat $INTERMEDIATE_OUTPUT_FILE | perl $SEARCH_GRAPH_WRAPPER $GRAPH_OUTPUT_FILE
	# echo "Generated $GRAPH_OUTPUT_FILE."
	# if [ $GRAPH ]; then
# #		if [ "$?" -eq 0 ]; then
		# set -e # start to fail on error
		# echo "Generating the graph..."
		# dot -Tps2 $GRAPH_OUTPUT_FILE > tmpSearchResults.ps
		# echo "Generated tmpSearchResults.ps."
		# ps2pdf tmpSearchResults.ps tmpSearchResults.pdf
		# echo "Generated tmpSearchResults.pdf."
		# #acroread tmpSearchResults.pdf &
		# set +e #stop failing on error
	# fi
	# #rm -f $INTERMEDIATE_OUTPUT_FILE
	# #rm -f $GRAPH_OUTPUT_FILE
# elif [ $PROFILE ]; then
	# if [ -f "maudeProfileDBfile.sqlite" ]; then
		# true
		# #echo "Database maudeProfileDBfile.sqlite already exists; will add results to it."
	# else
		# cp $SCRIPTS_DIR/maudeProfileDBfile.calibration.sqlite maudeProfileDBfile.sqlite
	# fi
	# INTERMEDIATE_OUTPUT_FILE=`mktemp -t $username-fsl-c.XXXXXXXXXXX`
	# #echo "Running the program..."
	# $DYNAMIC_MAUDE_COMMAND > $INTERMEDIATE_OUTPUT_FILE
	# cp $INTERMEDIATE_OUTPUT_FILE tmpProfileResults.txt
	# #echo "Analyzing results..."
	# cat $INTERMEDIATE_OUTPUT_FILE | perl $WRAPPER $PLAIN
	# RETVAL=$?
	# perl $SCRIPTS_DIR/analyzeProfile.pl $INTERMEDIATE_OUTPUT_FILE $PROGRAM_NAME
	# # cat $INTERMEDIATE_OUTPUT_FILE
	# # perl $SCRIPTS_DIR/printProfileData.pl -p > tmpProfileResults.csv
	# #echo "Results added to maudeProfileDBfile.sqlite.  Try running:"
	# #echo "cat $SCRIPTS_DIR/profile-executiveSummaryByProgram.sql | $SCRIPTS_DIR/accessProfiling.pl"
	# #echo "See $SCRIPTS_DIR/*.sql for some other example queries."
	# #echo "Done."
	# rm -f $INTERMEDIATE_OUTPUT_FILE
	# exit $RETVAL
# else
	# if [ $IOFLAG ]; then
		# perl $IO_SERVER &> tmpIOServerOutput.log &
		# PERL_SERVER_PID=$!
	# fi
	# $DYNAMIC_MAUDE_COMMAND | perl $WRAPPER $PLAIN
# fi
# RETVAL=$?
# if [ $IOFLAG ]; then
	# #echo "killing $PERL_SERVER_PID"
	# kill -s SIGINT $PERL_SERVER_PID &> /dev/null
# fi
# rm -f $FSL_C_RUNNER_FILE
# rm -f $STATIC_MAUDE_INPUT
# exit $RETVAL



sub runDebugger {
	my ($command) = (@_);
	print "Running $command\n";
	exec($command);
}


sub processStaticOutput {
	my ($str) = (@_);
	my @staticOutput = split(/\n/, $str);
	shift(@staticOutput);
	shift(@staticOutput);
	shift(@staticOutput);
	shift(@staticOutput);
	pop(@staticOutput);
	return join("\n", @staticOutput);
}
# more stuff is added during compilation

