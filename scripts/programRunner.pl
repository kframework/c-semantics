#!/usr/bin/env perl
use strict;
use File::Spec::Functions qw(rel2abs catfile);
use Getopt::Declare;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;
# use IO::File;
use IPC::Open3;

my $thisFile = "$0";
my @temporaryFiles = ();
my $PERL_SERVER_PID = 0;
my $childPid = 0;

setpgrp;
# END {kill 15, -$$}
#print "my pid is $$\n";

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
	# if ($childPid != 0) {
		# print "killing $childPid\n";
		# kill 1, $childPid;
	# }
	kill 1, -$$;
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
	#print "DEBUG_STATIC --- directly runs static semantics in maude so you can ctrl-c and debug\n";
	print "PLAIN --- prints out entire output without filtering it\n";
	print "SEARCH --- searches for all possible behaviors instead of interpreting\n";
	print "PROFILE --- performs semantic profiling using this program\n";
	print "GRAPH --- to be used with SEARCH=1; generates a graph of the state space\n";
	print "PRINTMAUDE --- simply prints out the raw Maude code; only of use to developers\n";
	print "E.g., DEBUG=1 $thisFile\n";
	print "\n";
	print "This message was displayed because the variable HELP was set.  Use HELP= $thisFile to turn off\n";
	exit(1);
}

if (defined($ENV{'PRINTMAUDE'})) {
	print linkedProgram();
	exit(0);
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
#my $username=`id -un`;

my $fileRunner = File::Temp->new( TEMPLATE => 'tmp-kcc-runner-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileRunner);
# my $fileDynamicRunner = File::Temp->new( TEMPLATE => 'tmp-kcc-runner-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
# #open my $fileDynamicRunner, ">fileDynamicRunner.maude";
# push(@temporaryFiles, $fileDynamicRunner);
my $fileInput = File::Temp->new( TEMPLATE => 'tmp-kcc-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileInput);
# my $fileDynamicInput = File::Temp->new( TEMPLATE => 'tmp-kcc-dynamic-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
# push(@temporaryFiles, $fileDynamicInput);

#my $fileStaticMaudeDefinition = catfile($SCRIPTS_DIR, 'static-c-total.maude');
my $fileMaudeDefinition;

if (defined($ENV{'SEARCH'})) {
	$fileMaudeDefinition = catfile($SCRIPTS_DIR, "c-total-nd.maude");
} else {
	$fileMaudeDefinition = catfile($SCRIPTS_DIR, "c-total.maude");
}

# create a file consisting of just the program (the tail of this script)
print $fileInput linkedProgram();
close($fileInput);

# first, set up the runner file with the right commands and set any variables
my $commandLineArguments = "";
for my $arg ($thisFile, @ARGV) {	
	$commandLineArguments .= "String \"$arg\"(.List{K}),, ";
}
my $startTerm = "eval(linked-program, ($commandLineArguments .List{K}), \"$stdin\")";
my $evalLine = "erew in C-program-linked : $startTerm .\n";
my $searchLine = "search in C-program-linked : $startTerm =>! B:Bag .\n";

if (defined($ENV{'PROFILE'})) {
	print $fileRunner "set profile on .\n";
	print $fileRunner "set profile on .\n";
}
if (defined($ENV{'DEBUG'})) {
	print $fileRunner "break select debug .\n";
	print $fileRunner "set break on .\n";
}
if (defined($ENV{'SEARCH'})) {
	print $fileRunner $searchLine;
	print $fileRunner "show search graph .\n"
} else {
	print $fileRunner $evalLine;
}
if (defined($ENV{'PROFILE'})) {
	print $fileRunner "show profile .\n";
}
if (! defined($ENV{'DEBUG'})) {
	print $fileRunner "q\n";
}
close($fileRunner);


# I had to add this strange true; thing to get it to work in windows.  no idea why...
my $maudeCommand = "true; maude -no-wrap -no-banner $fileMaudeDefinition " 
	. rel2abs($fileInput)
	. " " . rel2abs($fileRunner);

# now we can actually run maude on the runner file we built
# maude changes the way it behaves if it detects that it is working inside a pipe, so we have to call it differently depending on what we want
if (defined($ENV{'DEBUG'})) {
	#io
	exit runDebugger($maudeCommand);
} elsif (defined($ENV{'SEARCH'})) {
	my $intermediateOutputFile = "tmpSearchResults.txt";
	my $graphOutputFile = "tmpSearchResults.dot";
	if (! $ND_FLAG) {
		print "You did not compile this program with the '-n' setting.  You need to recompile this program using '-n' in order to see any non-linear state space.\n";
	}
	print "Performing the search...\n";
	my ($returnValue, @dynamicOutput) = runProgram($maudeCommand);
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
	
	my ($returnValue) = runProgram("$maudeCommand > $intermediateOutputFile");
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
			exec("perl $IO_SERVER > tmpIOServerOutput.log 2>&1");
			die "unable to exec: $!";
		}
	}
	my ($returnValue, @dynamicOutput) = runProgram($maudeCommand);
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
	$childPid = open P, "$command |" or die "Error running \"$command\"!";
	#print "for $command, pid is $childPid\n";
	my @data=<P>;
	close P;
	$childPid = 0;
	#print "child is dead\n";
	my $returnValue = $? >> 8;
	
	return ($returnValue, @data);
}

# sub runProgramSafe {
	# my ($command) = (@_);
	# #my @data = `$command`;
	
	# use Symbol 'gensym'; 
	# #my $inputfh;
	# my $input = gensym;
	# #open($inputfh, \@input);
	# my $outputfh;
	# my $output="";
	# open($outputfh, '>', \my $output);
	# #my $errorfh;
	# my $error = gensym;
	# #open($errorfh, \@error);
	# $childPid = open3($input, $outputfh, $error, $command);
	# waitpid $childPid, 0;
	# $childPid = 0;
	# close $outputfh;
	# print "output:\nxxx\n$output\nxxx\n";
	
	# return (0, $output);
# }


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

