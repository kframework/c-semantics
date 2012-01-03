use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use HTML::Entities;
# use IPC::Open3;

$| = 1;

use constant TOOL_FAILED_GOOD => 1;
use constant TOOL_FAILED_FIND => 2;
use constant TOOL_FOUND_BUG => 0;

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

my $kcc = "../dist/kcc";
# my $gcc = "gcc -gdwarf-2 -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99";

my $globalTests = "";
my $globalNumPassed = 0;
my $globalNumFailed = 0; # failures are tests that ran but failed
my $globalNumError = 0; # errors are tests that didn't finish running
my $globalTotalTime = 0;

###################################
my $gccCommand = 'gcc -gdwarf-2 -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99 ../tests/juliet/testcasesupport/io.c';

# my @compilers = (
	# [
		# 'gcc', 
		# "$gccCommand -Werror %s", 
		# './a.out'
	# ],
	# # [
		# # 'kcc', 
		# # "kcc -s %s",
		# # './a.out'
	# # ],
	# # [
		# # 'valgrind', 
		# # "$gccCommand %s", 
		# # 'valgrind -q --error-exitcode=1 --leak-check=no --undef-value-errors=yes ./a.out'
	# # ],
	# # [
		# # 'UBC', 
		# # 'clang -w -std=c99 -m32 -fcatch-undefined-c99-behavior -fcatch-undefined-nonarith-behavior %s', 
		# # './a.out'
	# # ],
	# # [
		# # 'ccured', 
		# # '~/tools/ccured/bin/ccured %s', 
		# # './a.out'
	# # ],
	# # # [ # doesn't seem to find anything
		# # # 'fjalar', 
		# # # "$gccCommand %s", 
		# # # '~/fjalar-1.4/inst/bin/valgrind -q --error-exitcode=1 --tool=fjalar --leak-check=no --xml-output-file=fjalar.out.xml ./a.out'
	# # # ],
	# # [ # doesn't work well without annotations
		# # 'deputy', 
		# # 'deputy --trust -lm -Wall -Wextra -O0 -m32 -U __GNUC__ -pedantic -std=c99 %s', 
		# # './a.out'
	# # ],
	# # [
		# # 'frama-c', 
		# # # '[ ! `frama-c -val -val-signed-overflow-alarms -slevel 100 %s | grep assert` ]',
		# # 'true',
		# # '[ ! `frama-c -val -val-signed-overflow-alarms -unspecified-access -obviously-terminates -machdep x86_64 -cpp-command "gcc -C -E -m64 -Dprintf=Frama_C_show_each -Iruntime" -precise-unions -big-ints-hex 0 -no-val-show-progress %s | grep assert` ]',
	# # ],
	
# );

my $_timer = [gettimeofday];
my $_testName = "";
my $_toolName = "";
#my $_testPhase = 0;

# bench('badArithmetic');
# bench('badPointers');
# bench('badMemory');
# bench('gcc.all');
# bench('custom');
printResult("Test", "Pass", "Tool", "", "", "");
bench('../tests/juliet/finalgood', '../tests/juliet/finalbad');
# bench('../tests/shouldFail');
# bench('../tests/mustFail');


# wine cmd /C "c:\Program Files\SemanticDesigns\DMS\executables\DMSCheckPointer.cmd C~GCC3 -cache ./cache-file -config ./init.h -target out.over -source . over.c"

my %seenFilenames = ();

sub bench {
	my ($gooddir, $baddir) = (@_);
	opendir (DIR, $baddir) or die $!;
	while (my $file = readdir(DIR)) {
		next if !($file =~ m/\.c$/);
		my ($baseFilename, $dirname, $suffix) = fileparse($file, ".c");
		$_testName = $file;
		if ($baseFilename =~ /^(.*)[a-z]$/) {
			my $rootFilename = $1;
			$_testName = $rootFilename;
			if ($seenFilenames{$rootFilename}) { next; }
			$seenFilenames{$rootFilename} = 1;
			$file = "$rootFilename*.c";
		}
		my $badfilename = "$baddir/$file";
		my $goodfilename = "$gooddir/$file";
		
		# print "Running valgrind with $goodfilename, $badfilename\n";
		valgrind($goodfilename, $badfilename);
		# $_timer = [gettimeofday];
		# $_testPhase = 0;
		# valgrindTest($goodfilename);
		
		# $_timer = [gettimeofday];
		# $_testPhase = 1;
		# valgrindTest($badfilename);
		
		# gccTest($file, $filename);
		# for my $stuff (@compilers) {
			# #my ($name, $compiler, $runner) = @$stuff;
			# unlink('a.out');
			# if (compile($file, $filename, @$stuff)) {
				# # dynamic($file, $filename, @$stuff);
			# }
		# }
		# print "$file\n";
	}
	closedir(DIR);
}

sub printResult {
	my ($dir, $dynamic, $name, $file, $retval, $length, $elapsed) = (@_);
	printf("%-17s\t%s\t%-10s\t%-10s\t%-10s\t%-10s\n", $dir, $dynamic, $name, $retval, $length, $elapsed);
}

sub report {
	my ($result, $msg) = (@_);
	my $elapsed = tv_interval($_timer, [gettimeofday]);
	printf("%-17s\t%s\t%-5s\t%.3f\t%s\n", $_testName, $_toolName, $result, $elapsed, $msg);
}

# sub runtest {
	# my ($sub, $good, $bad) = (@_);
	# print "in runtest\n";
	# &$sub->($good, $bad);
	# print "back\n";
# }

# returns true when everything works but it fails to find a bug
# sub compile {
	# my ($testname, $filename, $name, $compiler, $runner) = (@_);
	# #print STDERR "Compiling $filename with $name\n";
	# my $compileString = "$compiler 2>&1";
	# $compileString =~ s/%s/$filename/;
	# my ($elapsed, $retval, @output) = run($compileString);
	# my $length = length(join('', @output));
	# print STDERR @output;
	# if ($retval != 0) {
		# printResult($testname, 0, $name, -1, $length, $elapsed);
		# return 0;
	# }
	# return 1;
# }

# sub dynamic {
	# my ($testname, $filename, $name, $compiler, $runner) = (@_);
	
	# my ($elapsed, $retval, @output) = run("$runner 2>&1");
	# my $length = length(join('', @output));
	# if ($name eq 'ccured') {
		# if ($retval == -1) { $retval = 1; }
	# } elsif ($name eq 'UBC') {
		# if ($length > 0) { $retval = 1; }
	# }
	# printResult($testname, 1, $name, $retval, $length, $elapsed);
# }

sub valgrind {
	my ($goodfile, $badfile) = (@_);
	use constant VALGRIND_NO_FAIL => 2;
	use constant VALGRIND_FOUND_BUG => 0;
	
	$_toolName = "Valgrind";
	my $template = "tools/valgrind.sh $_testName \"-gdwarf-2 -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99 ../tests/juliet/testcasesupport/io.c\" \"%s\"";
	my $command = $template;
	$command =~ s/%s/$goodfile/;
	if (performCommand($command) != VALGRIND_NO_FAIL) {
		return report(TOOL_FAILED_GOOD);
	}
	$command = $template;
	$command =~ s/%s/$badfile/;
	$_timer = [gettimeofday];
	if (performCommand($command) == VALGRIND_FOUND_BUG) {
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


# sub gccTest {
	# my ($testname, $filename) = (@_);
	# unlink('a.out');
	
	# my ($signal, $retval, $output, $stderr) = run("c99 -lm -O0 -m32 $filename");
	# if ($signal) {
		# report($testname, 'GCC', '0', "Failed to compile normally: signal $signal");
	# }
	# if ($retval) {
		# report($testname, 'GCC', '0', "Failed to compile normally: retval $retval");
	# }
	
	# report($testname, 'GCC', '???');

	
	# #print STDERR "Compiling $filename with $name\n";
	# # my $compileString = "$compiler 2>&1";
	# # $compileString =~ s/%s/$filename/;
	# # my ($signal, $retval, $output, $stderr) = run($compileString);

	# # my $length = length(join('', @output));
	# # print STDERR @output;
	# # if ($retval != 0) {
		# # printResult($testname, 0, $name, -1, $length, $elapsed);
		# # return 0;
	# # }
	# # return 1;
# }


sub run {
	my ($theircommand) = (@_);

	my $command = "$theircommand 1>stdout.txt 2>stderr.txt";
	# print "Running $command\n";
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
	
	open FILE, "stdout.txt" or die "Couldn't open file: $!"; 
	my $stdout = join("", <FILE>); 
	close FILE;
	open FILE, "stderr.txt" or die "Couldn't open file: $!"; 
	my $stderr = join("", <FILE>); 
	close FILE;

	$childPid = 0;
	return ($signal, $retval, $stdout, $stderr);
}
