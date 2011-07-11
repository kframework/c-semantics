use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use HTML::Entities;
use IPC::Open3;

my $childPid = 0;

my $kcc = "../dist/kcc";
# my $gcc = "gcc -gdwarf-2 -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99";

my $globalTests = "";
my $globalNumPassed = 0;
my $globalNumFailed = 0; # failures are tests that ran but failed
my $globalNumError = 0; # errors are tests that didn't finish running
my $globalTotalTime = 0;

###################################
my $gccCommand = 'gcc -gdwarf-2 -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99';

my @compilers = (
	[
		'gcc', 
		"$gccCommand -Werror %s", 
		'./a.out'
	],
	# [
		# 'kcc', 
		# "kcc -s %s",
		# './a.out'
	# ],
	[
		'valgrind', 
		"$gccCommand %s", 
		'valgrind -q --error-exitcode=1 --leak-check=no --undef-value-errors=yes ./a.out'
	],
	[
		'UBC', 
		'clang -w -std=c99 -m32 -fcatch-undefined-c99-behavior -fcatch-undefined-nonarith-behavior %s', 
		'./a.out'
	],
	[
		'ccured', 
		'~/tools/ccured/bin/ccured %s', 
		'./a.out'
	],
	# [ # doesn't seem to find anything
		# 'fjalar', 
		# "$gccCommand %s", 
		# '~/fjalar-1.4/inst/bin/valgrind -q --error-exitcode=1 --tool=fjalar --leak-check=no --xml-output-file=fjalar.out.xml ./a.out'
	# ],
	# [ # doesn't work well without annotations
		# 'deputy', 
		# 'deputy --trust -lm -Wall -Wextra -O0 -m32 -U __GNUC__ -pedantic -std=c99 %s', 
		# './a.out'
	# ],
	# [
		# 'frama-c', 
		# 'frama-c -val -val-signed-overflow-alarms -slevel 100 %s',
		# 'true'
	# ],
	
);

# bench('badArithmetic');
# bench('badPointers');
# bench('badMemory');
# bench('gcc.all');
bench('custom');

sub bench {
	my ($dir) = (@_);
	opendir (DIR, $dir) or die $!;
	while (my $file = readdir(DIR)) {
		next if !($file =~ m/\.c$/);
		for my $stuff (@compilers) {
			my ($name, $compiler, $runner) = @$stuff;
			unlink('a.out');
			
			#####
			{
				my $filename = "$dir/$file";
				my $compileString = "$compiler 2>&1";
				$compileString =~ s/%s/$filename/;
				my ($elapsed, $retval, @output) = run($compileString);
				my $length = length(join('', @output));
				if ($retval != 0) {
					printf("%-10s\t0\t%-10s\t%-17s\t%-10d\t%-10s\t%-10s\n", $dir, $name, $file, -1, $length, $elapsed);
					next;
				} else {
					my ($elapsed, $retval, @output) = run("$runner 2>&1");
					my $length = length(join('', @output));
					if ($name eq 'ccured') {
						if ($retval == -1) { $retval = 1; }
					} elsif ($name eq 'UBC') {
						if ($length > 0) { $retval = 1; }
					}
					printf("%-10s\t1\t%-10s\t%-17s\t%-10d\t%-10s\t%-10s\n", $dir, $name, $file, $retval, $length, $elapsed);
				}
			}
			
			#####
			
		}
		# print "$file\n";
	}
	closedir(DIR);
}

#run("$kcc adhoc/nondet.c -o && SEARCH=1 ./adhoc.o");


# sub run {
	# my ($command) = (@_);
	# my $timer = [gettimeofday];
	# my $output = `$command 2>&1`;
	# my $retval = $? >> 8;
	# my $elapsed = tv_interval($timer, [gettimeofday]);
	# return ($elapsed, $output, $retval);
# }

sub run {
	my ($command) = (@_);
	my $timer = [gettimeofday];
	# print "Running $command\n";
	$childPid = open P, "$command |" or die "Error running \"$command\"!";
	my @data=<P>;
	close P;
	# my $retval = $? >> 8;
	my $retval = 0;
	if ($? == -1) {
		# print "failed to execute: $!\n";
		$retval = -1;
	} elsif ($? & 127) {
		# $signal = ($? & 127);
		# $dump = ($? & 128);
		# $result = '-1';
		$retval = -1;
		# printf "child died with signal %d, %s coredump\n", ($? & 127), ($? & 128) ? 'with' : 'without';
	} else {
		# printf "child exited with value %d\n", $? >> 8;
		$retval = $? >> 8;
	}
	# my $retval = $?;
	my $elapsed = tv_interval($timer, [gettimeofday]);
	$childPid = 0;
		
	return ($elapsed, $retval, @data);
}
