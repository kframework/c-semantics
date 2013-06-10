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

setpgrp;

# these are compile time settings and are set by the compile script using this
# file as a template
my $SCRIPTS_DIR="EXTERN_SCRIPTS_DIR";
my $PROGRAM_NAME="EXTERN_IDENTIFIER";

my @temporaryFiles = ();
my $fileInput = File::Temp->new( TEMPLATE => 'tmp-kcc-in-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
my $fileOutput = File::Temp->new( TEMPLATE => 'tmp-kcc-out-XXXXXXXXXXX', SUFFIX => '.txt', UNLINK => 0 );
push(@temporaryFiles, $fileInput);
push(@temporaryFiles, $fileOutput);
print $fileInput linkedProgram();

my $thisFile = "$0";
my $PERL_SERVER_PID = 0;
my $childPid = 0;

my $compiledDef = catfile($SCRIPTS_DIR, "c-kompiled");

my @krun_args = (
#      "-verbose", 
#      "--output-mode", "pretty", 
      "--output-mode", "raw", 
      "--output", $fileOutput, 
      "--parser", "cat", 
      "--compiled-def", $compiledDef, 
      "--io", 
      $fileInput);

system("krun", @krun_args);

open(OUT, "<$fileOutput");

for (<OUT>) {
      if (/< resultValue > 'tv\(KList2KLabel # (-?\d+)\(\.KList\)\(\.KList\),,'t\(Set2KLabel \.Set\(\.KList\),,'int\(\.KList\)\)\) <\/ resultValue >/){
            exit($1);
      }
}

sub interruptHandler {
	finalCleanup(); # call single cleanup point
	kill 1, -$$;
	exit(1); # since we were interrupted, we should exit with a non-zero code
}

# this block gets run at the end of a normally terminating program, whether it
# simply exits, or dies.  We use this to clean up.
END {
	my $retval = $?; # $? contains the value the program would normally have exited with
	finalCleanup(); # call single cleanup point
	exit($retval);
}

# this subroutine can be used as a way to ensure we clean up all resources
# whenever we exit.  This is going to be mostly temp files.  If the program
# terminates for almost any reason, this code will be executed.
sub finalCleanup {
	if (!defined($ENV{'DUMPALL'})) {
		foreach my $file (@temporaryFiles) {
			close($file);
			unlink ($file);
		}
	}
}

if (defined($ENV{'HELP'})) {
	print "Here are some configuration variables you can set to affect how this program is run:\n";
	print "DEBUG --- directly runs maude so you can ctrl-c and debug\n";
	print "DEBUGON --- debugs a particular semantic rule\n";
	print "PLAIN --- prints out entire output without filtering it\n";
	print "SEARCH --- searches for all possible behaviors instead of interpreting\n";
	print "THREADSEARCH --- searches for all possible behaviors related to concurrency instead of interpreting\n";
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

if (defined($ENV{'IOLOG'})) {
}

# more stuff is added during compilation

