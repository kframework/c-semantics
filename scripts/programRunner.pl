#!/usr/bin/env perl
use POSIX;
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
	if (!defined($ENV{'DUMPALL'})) {
		foreach my $file (@temporaryFiles) {
			close($file);
			unlink ($file);
		}
	}
	# print "serverid = $PERL_SERVER_PID\n";
	if ($PERL_SERVER_PID > 0) {
		# my $ret = kill(SIGTERM, 0); # this works, but kills this script too
		my $ret = kill(SIGTERM, $PERL_SERVER_PID);
	}
}

if (defined($ENV{'HELP'})) {
	print "Here are some configuration variables you can set to affect how this program is run:\n";
	print "DEBUG --- directly runs maude so you can ctrl-c and debug\n";
	print "DEBUGON --- debugs a particular semantic rule\n";
	print "PLAIN --- prints out entire output without filtering it\n";
	print "SEARCH --- searches for all possible behaviors instead of interpreting\n";
	print "PROFILE --- performs semantic profiling using this program\n";
	print "GRAPH --- to be used with SEARCH=1; generates a graph of the state space\n";
	print "PRINTMAUDE --- simply prints out the raw Maude code; only of use to developers\n";
	print "LOADMAUDE --- loads this program into maude without executing; only of use to developers\n";
	print "TRACEMAUDE --- prints an execution trace; only of use to developers\n";
	print "IOLOG --- records a .log file showing what happens in the IO server\n";
	print "DUMPALL --- leaves all the intermediate files in the current directory\n";
	print "E.g., DEBUG=1 $thisFile\n";
	print "\n";
	print "This message was displayed because the variable HELP was set.  Use HELP= $thisFile to turn off\n";
	exit(1);
}

# may be many more of these
if (defined($ENV{'PROFILE'}) && defined($ENV{'TRACEMAUDE'})) {
	print STDERR "Error: Cannot use both PROFILE and TRACEMAUDE at the same time.\n";
	exit(1);
}

if (defined($ENV{'PRINTMAUDE'})) {
	print linkedProgram();
	exit(0);
}
my $iolog_flag = "";
if (defined($ENV{'IOLOG'})) {
	$iolog_flag = "--createLogs ";
}

# these are compile time settings and are set by the compile script using this file as a template
my $IO_SERVER="EXTERN_IO_SERVER";
# my $IOFLAG="EXTERN_COMPILED_WITH_IO";
my $SCRIPTS_DIR="EXTERN_SCRIPTS_DIR";
my $PROGRAM_NAME="EXTERN_IDENTIFIER";
# my $ND_FLAG=EXTERN_ND_FLAG;

my $wrapperScript = catfile($SCRIPTS_DIR, 'wrapper.pl');
require $wrapperScript;
my $graphScript = catfile($SCRIPTS_DIR, 'graphSearch.pl');
require $graphScript;

# print defined($ENV{'PLAIN'});
# print defined($ENV{'TRACEMAUDE'});
my $plainOutput = (defined($ENV{'PLAIN'}) or defined($ENV{'TRACEMAUDE'})) ? 1 : 0 ;
# print "plain: $plainOutput\n";

my $stdin="";
# actual start of script
if ( -t STDIN ) {
	$stdin=""; 
} else {
	$stdin=join("", <STDIN>);
}

my $fileRunner = File::Temp->new( TEMPLATE => 'tmp-kcc-runner-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileRunner);
my $fileCommand = File::Temp->new( TEMPLATE => 'tmp-kcc-cmd-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileCommand);

my $fileInput = File::Temp->new( TEMPLATE => 'tmp-kcc-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $fileInput);

my $traceFile;
if (defined($ENV{'TRACEMAUDE'})) {
	$traceFile = File::Temp->new( TEMPLATE => 'tmp-kcc-trace-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
	push(@temporaryFiles, $traceFile);
}

my $fileMaudeDefinition;

if (defined($ENV{'SEARCH'}) or defined($ENV{'MODELCHECK'})) {
	$fileMaudeDefinition = catfile($SCRIPTS_DIR, "c-total-nd.maude");
} else {
	$fileMaudeDefinition = catfile($SCRIPTS_DIR, "c-total.maude");
}

print $fileRunner "load $fileMaudeDefinition\n";
print $fileRunner "load $fileInput\n";
close($fileRunner);

# create a file consisting of just the program (the tail of this script)
print $fileInput linkedProgram();
close($fileInput);

# first, set up the runner file with the right commands and set any variables
my $commandLineArguments = "";
for my $arg ($thisFile, @ARGV) {	
	$commandLineArguments .= "# \"$arg\"(.List{K}),, ";
}
my $startTerm = "eval('linked-program(.List{K}), ($commandLineArguments .List{K}), \"\Q$stdin\E\")";
my $evalLine = "erew $startTerm .\n";
my $searchLine = "search in C-program-linked : $startTerm =>! B:Bag .\n";
my $modelLine = "red in C-program-linked : modelCheck(state($startTerm), k2model('LTLAnnotation(Id Identifier(\"$ENV{'MODELCHECK'}\")(.List{K}))) ) .\n";
#my $modelLine = "--- red modelCheck(state($startTerm), k2model('LTLAnnotation(Id Identifier(\"$ENV{'MODELCHECK'}\")(.List{K}))) ) .";
# $modelLine .= "red k2model('LTLAnnotation(Id Identifier(\"$ENV{'MODELCHECK'}\")(.List{K}))) .\n";

# print $fileCommand "set print attribute on .\n";

if (defined($ENV{'PROFILE'})) {
	print $fileCommand "set profile on .\n";
	print $fileCommand "set profile on .\n";
}
if (defined($ENV{'DEBUG'})) {
	print $fileCommand "break select debug .\n";
	print $fileCommand "set break on .\n";
}
if (defined($ENV{'TRACEMAUDE'})) {
	print $fileCommand "set trace on .\n";
}
if (defined($ENV{'DEBUGON'})) {
	print $fileCommand "break select $ENV{'DEBUGON'} .\n";
	print $fileCommand "set break on .\n";
}

if (defined($ENV{'SEARCH'})) {
	print $fileCommand $searchLine;
	print $fileCommand "show search graph .\n"
} elsif (defined($ENV{'MODELCHECK'})) {
	print $fileCommand $modelLine;
} elsif (! defined($ENV{'LOADMAUDE'})) {
	print $fileCommand $evalLine;
}
if (defined($ENV{'PROFILE'})) {
	print $fileCommand "show profile .\n";
}
if (! defined($ENV{'DEBUG'}) and ! defined($ENV{'DEBUGON'}) and ! defined($ENV{'LOADMAUDE'})) {
	print $fileCommand "q\n";
}

close($fileCommand);


# I had to add this strange true; thing to get it to work in windows.  no idea why...
my $maudeCommand = "true; maude -no-wrap -no-banner " . rel2abs($fileRunner) . " " . rel2abs($fileCommand);

# now we can actually run maude on the runner file we built
# maude changes the way it behaves if it detects that it is working inside a pipe, so we have to call it differently depending on what we want
if (defined($ENV{'DEBUG'}) or defined($ENV{'DEBUGON'}) or defined($ENV{'LOADMAUDE'})) {
	#io
	exit runDebugger($maudeCommand);
} elsif (defined($ENV{'SEARCH'})) {
	my $intermediateOutputFile = "tmpSearchResults.txt";
	my $graphOutputFile = "tmpSearchResults.dot";
	# if (! $ND_FLAG) {
		# print "You did not compile this program with the '-n' setting.  You need to recompile this program using '-n' in order to see any non-linear state space.\n";
	# }
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
} else {
	my ($returnValue, $signal, $screenOutput, @dynamicOutput) = runWrapper($fileRunner, $fileCommand);
	if ($returnValue != 0 or $signal != 0) {
		die "Dynamic execution failed: $returnValue";
	}	
	my ($finalReturnValue, $finalOutput) = maudeOutputWrapper($plainOutput, $screenOutput, @dynamicOutput);
		
	if (defined($ENV{'PROFILE'})) {
		if (! -e "maudeProfileDBfile.sqlite") {
			copy(catfile($SCRIPTS_DIR, "maudeProfileDBfile.calibration.sqlite"), "maudeProfileDBfile.sqlite");
		}
		my $intermediateOutputFile = File::Temp->new( TEMPLATE => 'tmp-kcc-intermediate-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
		push(@temporaryFiles, $intermediateOutputFile);
		writeToFile($intermediateOutputFile, @dynamicOutput);
		my $profileWrapper = catfile($SCRIPTS_DIR, 'analyzeProfile.pl');
		`perl $profileWrapper $intermediateOutputFile $PROGRAM_NAME`;
	}
	
	if (defined($ENV{'TRACEMAUDE'})) {
		print $traceFile $finalOutput;
		close $traceFile;
		print "Trace placed in $traceFile\n";
	} else {
		print $finalOutput;
	}
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
# runs a command and returns a pair (return value, output)
sub runWrapper {
	my ($runner, $maudeCommand) = (@_);
	my $outfile;
	$outfile = File::Temp->new( TEMPLATE => 'tmp-kcc-out-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
	push(@temporaryFiles, $outfile);
	my $errorFile;
	$errorFile = File::Temp->new( TEMPLATE => 'tmp-kcc-err-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
	push(@temporaryFiles, $errorFile);

	my $command = "$IO_SERVER --commandFile $maudeCommand --maudeFile $runner --outputFile $outfile --errorFile $errorFile --moduleName C-program-linked $iolog_flag";
	$childPid = open P, "$command |" or die "Error running \"$command\"!";
	#print "for $command, pid is $childPid\n";
	#my @data=<P>;
	# while (defined(my $line = <P>)) {
	my $screenOutput = "";
	$| = 1; # autoflush
	my $char;
	while (read (P, $char, 1)) {
		$screenOutput .= $char;
		print "$char";
	}
	$| = 0; # no autoflush
	close P;
	#print @data;
	$childPid = 0;
	#print "child is dead\n";
	my $code = $?;
	my $returnValue = $code >> 8;
	my $signal = ($code & 127);
	
	open FILE, "<", $outfile;
	my @lines = <FILE>;
	close FILE;
	open FILE, "<", $errorFile;
	my @xlines = <FILE>;
	close FILE;
	print @xlines;
	
	# print "$returnValue, $signal\n";
	return ($returnValue, $signal, $screenOutput, @lines);
}

sub runDebugger {
	my ($command) = (@_);
	print "Running $command\n";
	exec($command);
}

sub writeToFile {
	my ($file, @data) = (@_);
	open (MYFILE, ">$file");
	for my $line  (@data) {
		print MYFILE $line;
	}
	close (MYFILE);
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

