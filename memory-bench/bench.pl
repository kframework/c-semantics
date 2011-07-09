use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use HTML::Entities;
use IPC::Open3;

my $childPid = 0;

my $kcc = "../dist/kcc";
my $gcc = "gcc -gdwarf-2 -lm -Werror -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99";

my $globalTests = "";
my $globalNumPassed = 0;
my $globalNumFailed = 0; # failures are tests that ran but failed
my $globalNumError = 0; # errors are tests that didn't finish running
my $globalTotalTime = 0;

###################################
my $gccCommand = 'gcc -lm -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99';

my @compilers = (
	# [
		# 'gcc', 
		# "$gccCommand %s", 
		# './a.out'
	# ],
	# [
		# 'valgrind', 
		# "$gccCommand %s", 
		# 'valgrind -q --error-exitcode=1 --leak-check=no --undef-value-errors=yes ./a.out'
	# ],
	# [
		# 'valgrind', 
		# "$gccCommand %s", 
		# 'valgrind -q --error-exitcode=1 --leak-check=no --undef-value-errors=yes --tool=ptrcheck ./a.out'
	# ],
	[
		'UBC', 
		'clang -w -std=c99 -m32 -fcatch-undefined-c99-behavior -fcatch-undefined-nonarith-behavior %s', 
		'./a.out'
	],
	# [
		# 'ccured', 
		# '~/tools/ccured/bin/ccured %s', 
		# './a.out'
	# ],
	# [
		# 'fjalar', 
		# "$gccCommand %s", 
		# '~/fjalar-1.4/inst/bin/valgrind -q --error-exitcode=1 --tool=fjalar ./a.out'
	# ],
	# [
		# 'deputy', 
		# 'deputy --opt=0 -gdwarf-2 -lm -Wall -Wextra -O0 -m32 -U __GNUC__ -pedantic -std=c99 %s', 
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
bench('gcc.all');

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
					printf("%-10s\t0\t%-10s\t%-14s\t%-10s\t%-10s\t%-10s\n", $dir, $name, $file, 'xxx', $length, $elapsed);
					next;
				} else {
					my ($elapsed, $retval, @output) = run("$runner 2>&1");
					my $length = length(join('', @output));
					printf("%-10s\t1\t%-10s\t%-14s\t%-10s\t%-10s\t%-10s\n", $dir, $name, $file, $retval, $length, $elapsed);
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
	#print "Running $command\n";
	$childPid = open P, "$command |" or die "Error running \"$command\"!";
	my @data=<P>;
	close P;
	#my $retval = $? >> 8;
	my $retval = $?;
	my $elapsed = tv_interval($timer, [gettimeofday]);
	$childPid = 0;
	
	
	return ($elapsed, $retval, @data);
}
