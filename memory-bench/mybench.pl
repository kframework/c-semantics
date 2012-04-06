#  ~/tools/ccured/bin/ccured -o foo.a -DOMITGOOD -DINCLUDEMAIN --includedir=../tests/juliet/testcasesupport ../tests/juliet/testcasesupport/io.c ../tests/juliet/finalpre/CWE122_Heap_Based_Buffer_Overflow__c_dest_int_memmove_45.c
# the above fails nondeterministically

# ~/tools/ccured/bin/ccured -o foo.a -DOMITBAD -DINCLUDEMAIN --includedir=../tests/juliet/testcasesupport ../tests/juliet/testcasesupport/io.c ../tests/juliet/finalpre/CWE122_Heap_Based_Buffer_Overflow__c_dest_int_memmove_45.c
# the above actually segfaults, which suggests there might be a bug in ccured


use strict;
use File::Spec::Functions qw(rel2abs catfile);
use Cwd 'abs_path';
use Time::HiRes qw(gettimeofday tv_interval);
use File::Temp qw/ tempfile tempdir /;
use File::Basename;
use Text::Diff;
use HTML::Entities;
# use IPC::Open3;

my $myDirectory = dirname(rel2abs($0));

$| = 1;

my $numArgs = $#ARGV + 1;
if ($numArgs != 1) {
	die "Please pass the number of the test you want to run\n";
}
my $testToRun = $ARGV[0];

use constant TOOL_FAILED_GOOD => "Died";
use constant TOOL_FAILED_FIND => "False negative";
use constant TOOL_FALSE_ALARM => "False positive";
use constant TOOL_FOUND_BUG => "Success";

use constant SCRIPT_NO_FAIL => 2;
use constant SCRIPT_FOUND_BUG => 0;

setpgrp;
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
	print "in handler\n";
	# finalCleanup(); # call single cleanup point
	kill 1, -$$;
	exit(1); # since we were interrupted, we should exit with a non-zero code
}

my $childPid = 0;

# my $gcc = "gcc -gdwarf-2 -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99";

my $globalTests = "";
my $globalNumPassed = 0;
my $globalNumFailed = 0; # failures are tests that ran but failed
my $globalNumError = 0; # errors are tests that didn't finish running
my $globalTotalTime = 0;

###################################
my $gccCommand = 'gcc -gdwarf-2 -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99 ../tests/juliet/testcasesupport/io.c';

my $_timer = [gettimeofday];
my $_testName = "";
my $_toolName = "";
#my $_testPhase = 0;

# bench('badArithmetic');
# bench('badPointers');
# bench('badMemory');
# bench('gcc.all');
# bench('custom');
printHeader();

# bench('../tests/juliet/finalgood', '../tests/juliet/finalbad');
# bench("$myDirectory/finalpre/$testToRun");
bench("$myDirectory/allgood");
# bench('finalpre/1');
# bench('finalpre/2');
# bench('finalpre/3');
# bench('../tests/shouldFail');
# bench('../tests/mustFail');


# wine cmd /C "c:\Program Files\SemanticDesigns\DMS\executables\DMSCheckPointer.cmd C~GCC3 -cache ./cache-file -config ./init.h -target out.over -source . over.c"

my %seenFilenames = ();

sub bench {
	my ($testdir) = (@_);
	opendir (DIR, $testdir) or die $!;
	# print "benching $testdir\n";
	while (my $file = readdir(DIR)) {
		next if !($file =~ m/\.c$/);
		my ($baseFilename, $dirname, $suffix) = fileparse($file, ".c");
		$_testName = $file;
		# my $secFiles = "$testdir/$dirname$baseFilename.sec.c";
		# if ($baseFilename =~ /^(.*)[a-z]$/) {
			# my $rootFilename = $1;
			# $_testName = $rootFilename;
			# if ($seenFilenames{$rootFilename}) { next; }
			# $seenFilenames{$rootFilename} = 1;
			# $file = "$rootFilename*.c";
			# $secFiles = "$testdir/$rootFilename*.sec.c";
		# }
		# my $testfilename = abs_path("$testdir/$file");
		my $testfilename = $file;
		
		
		# print "Running valgrind with $goodfilename, $badfilename\n";
		# print "$testfilename\n";
		# valgrind($testfilename);
		# # ubc($testfilename);
		# framac($testfilename);
		# kcc($testfilename);
		# ccured($testfilename);
		checkPointer($testfilename);
		
		`mv $testfilename $myDirectory/allgood/done/`;
		
	}
	closedir(DIR);
}

sub printHeader {
	printf("%-75s\t%-10s\t%-15s\t%s\t%s\n", "Test", "Tool", "Status", "Time");
}

sub report {
	my ($result, $msg) = (@_);
	my $elapsed = tv_interval($_timer, [gettimeofday]);
	printf("%-75s\t%-10s\t%-15s\t%.3f\t%s\n", $_testName, $_toolName, $result, $elapsed, $msg);
}


sub valgrind {
	my ($file) = (@_);
	
	$_toolName = "Valgrind";
	my $template = "$myDirectory/tools/valgrind.sh $_testName \"-gdwarf-2 -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99 $myDirectory/%s/$file\" ";
	my $goodCommand = $template;
	$goodCommand =~ s/%s/allgood/;
	my $badCommand = $template;
	$badCommand =~ s/%s/allbad/;
	genericTestHandler($goodCommand, $badCommand);
}

# sub ubc {
	# my ($file) = (@_);
	# $_toolName = "ubc";
	# my $template = "$myDirectory/tools/ubc.sh $_testName \"-I$myDirectory/../tests/juliet/testcasesupport %s -DINCLUDEMAIN -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99 $myDirectory/../tests/juliet/testcasesupport/io.c $file\" ";
	# my $goodCommand = $template;
	# $goodCommand =~ s/%s/-DOMITBAD/;
	# my $badCommand = $template;
	# $badCommand =~ s/%s/-DOMITGOOD/;
	# genericTestHandler($goodCommand, $badCommand);
# }

sub kcc {
	my ($file) = (@_);
	
	$_toolName = "kcc";
	my $template = "$myDirectory/tools/kcc.sh $_testName \"$myDirectory/%s/$file\"";
	my $goodCommand = $template;
	$goodCommand =~ s/%s/allgood/;
	my $badCommand = $template;
	$badCommand =~ s/%s/allbad/;
	genericTestHandler($goodCommand, $badCommand);
}

sub ccured {
	my ($file) = (@_);
	
	$_toolName = "ccured";
	my $template = "$myDirectory/tools/ccured.sh $_testName \"$myDirectory/%s/$file\"";
	my $goodCommand = $template;
	$goodCommand =~ s/%s/allgood/;
	my $badCommand = $template;
	$badCommand =~ s/%s/allbad/;
	genericTestHandler($goodCommand, $badCommand);
}

sub framac {
	my ($file) = (@_);
	
	$_toolName = "framac";
	my $template = "$myDirectory/tools/framac.sh $_testName \"-I$myDirectory/frama-c-Nitrogen-20111001+dev/share/libc -I$myDirectory/frama-c-Nitrogen-20111001+dev/share\" \"$myDirectory/frama-c-Nitrogen-20111001+dev/share/libc.c $myDirectory/%s/$file\"";
	my $goodCommand = $template;
	$goodCommand =~ s/%s/allgood/;
	my $badCommand = $template;
	$badCommand =~ s/%s/allbad/;
	genericTestHandler($goodCommand, $badCommand);
}

sub checkPointer {
	my ($file, $secfiles) = (@_);
	
	$_toolName = "checkPointer";
	my $template = "$myDirectory/tools/checkpointer.sh $_testName \"$myDirectory/%s/$file\" \"\" \"asdfdsaf.sec.c\" \"..\/initGood.h\"";
	my $goodCommand = $template;
	$goodCommand =~ s/%s/allgood/;
	my $badCommand = $template;
	$badCommand =~ s/%s/allbad/;
	genericTestHandler($goodCommand, $badCommand);
}

sub genericTestHandler {
	my ($goodCommand, $badCommand) = (@_);
	
	$_timer = [gettimeofday];
	# $command =~ s/%s/$goodfile/;
	my $goodResult = performCommand($goodCommand);
	if ($goodResult == SCRIPT_FOUND_BUG) {
		return report(TOOL_FALSE_ALARM);
	}
	if ($goodResult != SCRIPT_NO_FAIL) {
		return report(TOOL_FAILED_GOOD);
	}
	# $command = $template;
	# $command =~ s/%s/$badfile/;
	$_timer = [gettimeofday];
	my $badResult = performCommand($badCommand);
	if ($badResult == SCRIPT_FOUND_BUG) {
		return report(TOOL_FOUND_BUG);
	}
	return report(TOOL_FAILED_FIND);
}

sub reportSuccess {
	report('0');
}

sub performCommand {
	my ($command) = (@_);
	my ($signal, $retval, $output, $stderr) = run($command);
	if ($signal) {
		# report($signal, "Failed to run normally: signal $signal");
		return -$signal;
	}
	return $retval;
}


sub run {
	my ($theircommand) = (@_);
	my $stdoutFile = File::Temp->new( TEMPLATE => 'tmp-bench-XXXXXXXXXXX', SUFFIX => '.stdout', UNLINK => 0 );
	my $stderrFile = File::Temp->new( TEMPLATE => 'tmp-bench-XXXXXXXXXXX', SUFFIX => '.stderr', UNLINK => 0 );
	close($stdoutFile);
	close($stderrFile);
	
	my $command = "$theircommand 1>$stdoutFile 2>$stderrFile";
	# print STDERR "Running $command\n";
	$childPid = open P, "$command |" or die "Error running \"$command\"!";
	#my @data=<P>;
	close P;
	# my $retval = $? >> 8;
	my $retval = 0;
	if ($? == -1) {
		# print "failed to execute: $!\n";
		$retval = -1;
	} else {
		# printf "child exited with value %d\n", $? >> 8;
		$retval = $? >> 8;
	}
	my $signal = ($? & 127);
	
	open FILE, $stdoutFile or die "Couldn't open file: $!"; 
	my $stdout = join("", <FILE>); 
	close FILE;
	open FILE, $stderrFile or die "Couldn't open file: $!"; 
	my $stderr = join("", <FILE>); 
	close FILE;

	unlink($stdoutFile) or warn "Could not unlink $stdoutFile: $!";
	unlink($stderrFile) or warn "Could not unlink $stderrFile: $!";
	$childPid = 0;
	return ($signal, $retval, $stdout, $stderr);
}
