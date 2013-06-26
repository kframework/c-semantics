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

setpgrp;

# here we trap control-c (and others) so we can clean up when that happens
$SIG{'ABRT'} = 'interruptHandler';
$SIG{'TERM'} = 'interruptHandler';
$SIG{'QUIT'} = 'interruptHandler';
$SIG{'SEGV'} = 'interruptHandler';
$SIG{'HUP' } = 'interruptHandler';
$SIG{'TRAP'} = 'interruptHandler';
$SIG{'STOP'} = 'interruptHandler';
$SIG{'INT'} = 'interruptHandler'; # handle control-c 

# these are compile time settings and are set by the compile script using this
# file as a template
my $SCRIPTS_DIR = "EXTERN_SCRIPTS_DIR";
my $PROGRAM_NAME = "EXTERN_IDENTIFIER";

my @temporaryFiles = ();
my $fileInput = File::Temp->new( TEMPLATE => 'tmp-kcc-in-XXXXXXXXXXX', SUFFIX => '.c', UNLINK => 0 );
my $fileOutput = File::Temp->new( TEMPLATE => 'tmp-kcc-out-XXXXXXXXXXX', SUFFIX => '.txt', UNLINK => 0 );
push(@temporaryFiles, $fileInput);
push(@temporaryFiles, $fileOutput);

# The function "linkedProgram()" is attached to the bottom of this script by kcc.
print $fileInput linkedProgram();

my $PERL_SERVER_PID = 0;
my $childPid = 0;

my $argc = $#ARGV < 0? 1 : $#ARGV + 1;
my $argv = join(',,', map {qq|"$_"|} ($0, @ARGV));

my %krun_args = (
#     '-verbose' => '',
#     '--output-mode' => 'pretty', 
      '--output-mode' => 'raw', 
      '--output' => $fileOutput, 
      '--parser' => 'cat', 
      '--compiled-def' => catfile($SCRIPTS_DIR, "c-kompiled"), 
      '--io' => '', 
      "-cARGC=$argc" => '',
      "-cARGV=$argv,,.KList" => '',
      '' => $fileInput
);

# this block gets run at the end of a normally terminating program, whether it
# simply exits, or dies.  We use this to clean up.
END {
	my $retval = $?; # $? contains the value the program would normally have exited with
	finalCleanup(); # call single cleanup point
	exit($retval);
}

sub interruptHandler {
	finalCleanup(); # call single cleanup point
	kill 1, -$$;
	exit(1); # since we were interrupted, we should exit with a non-zero code
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
	print "E.g., DEBUG=1 $0\n";
	print "\n";
	print "This message was displayed because the variable HELP was set.  Use HELP=1 $0 to turn off\n";
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

if (defined($ENV{'SEARCH'})) {
      $krun_args{'--search'} = '';
      delete $krun_args{'--io'};
      $krun_args{'--no-io'} = '';
      $krun_args{'--output-mode'} = 'pretty';
      delete $krun_args{'--output'};
      $krun_args{'--compiled-def'} = catfile($SCRIPTS_DIR, "c-kompiled-nd");
}

if (defined($ENV{'LTLMC'})) {
      $krun_args{'--ltlmc'} = $ENV{'LTLMC'};
      delete $krun_args{'--io'};
      $krun_args{'--no-io'} = '';
      $krun_args{'--output-mode'} = 'pretty';
      delete $krun_args{'--output'};
      $krun_args{'--compiled-def'} = catfile($SCRIPTS_DIR, "c-kompiled-nd");
}

system("krun", grep {$_} %krun_args);

open(OUT, "<$fileOutput");

my $exitCode = 1;
my $finalComp = "";
my $finalCompGoto = "";
my $finalCompType = "";

my $errorMsg = "";
my $errorFile = "";
my $errorFunc = "";
my $errorLine = "";

my $haveError = 0;
my $haveExitCode = 0;

for (<OUT>) {
      /< k > (.*) <\/ k >/ && do {
            $haveError = 1;
            $finalComp = $1;
      };

      /< errorCell > # "(.*)"\(\.KList\) <\/ errorCell >/ && do {
            $haveError = 1;
            my $output = $1;
            $output =~ s/\%/\%\%/g;
            $output =~ s/`/\\`/g;
            $output =~ s/\\\\/\\\\\\\\/g;
            $errorMsg = substr(`printf "x$output"`, 1);
      };

      /< currentFunction > 'Identifier\(# "(.*)"\(\.KList\)\) <\/ currentFunction >/ && do {
            $errorFunc = $1;
      };
      
      /< currentProgramLoc > 'CabsLoc\(# "(.*)"\(\.KList\),,# (\d+).*<\/ currentProgramLoc >/ && do {
            $errorFile = $1;
            $errorLine = $2;
      };
      
      /< finalComputation > (.*) <\/ finalComputation >/ && do {
            $haveError = 1;
            $finalComp = $1;
      };
      
      /< computation > (.*) <\/ computation >/ && do {
            $haveError = 1;
            $finalCompGoto = $1;
      };

      /< type > (.*) <\/ type >/ && do {
            $haveError = 1;
            $finalCompType = $1;
      };

      /< resultValue > 'tv\(KList2KLabel # (-?\d+)\(\.KList\)\(\.KList\),,'t\(Set2KLabel \.Set\(\.KList\),,'int\(\.KList\)\)\) <\/ resultValue >/ && do {
            $haveExitCode = 1;
            $exitCode = $1;
      };
}

if (!$ENV{'SEARCH'} && ($haveError || !$haveExitCode)) {
      print "\n=============================================================\n";
      print "ERROR! KCC encountered an error while executing this program.\n";

      if ($errorMsg ne "") {
            print "=============================================================\n";
            print "$errorMsg\n";
      }

      print "=============================================================\n";
      print "File: $errorFile\n";
      print "Function: $errorFunc\n";
      print "Line: $errorLine\n";

      if ($finalComp ne "") {
            print "=============================================================\n";
            print "Final Computation:\n";
            print substr($finalComp, 0, 1000);
            print "\n";
      }

      if ($finalCompGoto ne "") {
            print "=============================================================\n";
            print "Final Goto Map Computation:\n";
            print substr($finalCompGoto, 0, 1000);
            print "\n";
      }

      if ($finalCompType ne "") {
            print "=============================================================\n";
            print "Final Type Computation:\n";
            print substr($finalCompType, 0, 1000);
            print "\n";
      }
}

exit($exitCode);

# more stuff is added during compilation

