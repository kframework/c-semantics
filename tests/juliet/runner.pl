use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use HTML::Entities;
use File::Spec::Functions qw(rel2abs catfile);
# use IPC::Open3;

my $_timer = [gettimeofday];
my $childPid = 0;

# good
# bench("testcases/CWE121_Stack_Based_Buffer_Overflow");
# bench("testcases/CWE122_Heap_Based_Buffer_Overflow");
# bench("testcases/CWE124_Buffer_Underwrite");
# bench("testcases/CWE126_Buffer_Overread");
# bench("testcases/CWE127_Buffer_Underread");
# bench("testcases/CWE131_Incorrect_Calculation_Of_Buffer_Size");
# bench("testcases/CWE170_Improper_Null_Termination");
# bench("testcases/CWE193_Off_by_One_Error");
# bench("testcases/CWE369_Divide_By_Zero");
# bench("testcases/CWE562_Return_Of_Stack_Variable_Address");
# bench("testcases/CWE590_Free_Of_Invalid_Pointer_Not_On_The_Heap");
# bench("testcases/CWE665_Improper_Initialization");
# bench("testcases/CWE680_Integer_Overflow_To_Buffer_Overflow");
# bench("testcases/CWE685_Function_Call_With_Incorrect_Number_Of_Arguments");
# bench("testcases/CWE688_Function_Call_With_Incorrect_Variable_Or_Reference_As_Argument");
# bench("testcases/CWE761_Free_Pointer_Not_At_Start_Of_Buffer");
# bench("testcases/CWE457_Use_of_Uninitialized_Variable");
# bench("testcases/CWE469_Use_Of_Pointer_Subtraction_To_Determine_Size");
# bench("testcases/CWE758_Undefined_Behavior");

# not catching memcpy bugs
bench("testcases/CWE475_Undefined_Behavior_For_Input_to_API");

# weird
# bench("testcases/CWE369_Divide_By_Zero"); # their rand has overflow :/


my %seenFilenames = ();

sub bench {
	my ($dir) = (@_);
	opendir (DIR, $dir) or die $!;
	while (my $file = readdir(DIR)) {
		next if !($file =~ m/\.c$/);
		my ($baseFilename, $dirname, $suffix) = fileparse($file, ".c");
		# print "$baseFilename\n";
		if ($baseFilename =~ /^(.*)[a-z]$/) {
			my $rootFilename = $1;
			# print "root filename = $rootFilename\n";
			if ($seenFilenames{$rootFilename}) { next; }
			# print "root file name unseen\n";
			$seenFilenames{$rootFilename} = 1;
			$file = "$rootFilename*.c";
		}
		my $filename = "$dir/$file";
		$_timer = [gettimeofday];
		
		test($file, $filename);
		
	}
	closedir(DIR);
}

sub test {
	my ($testname, $filename) = (@_);
	my $tool = 'kcc';
	
	my ($signal, $retval, $output, $stderr) = run("./juliet.pl $tool \"$filename\"");
	if ($signal) {
		return report($testname, $tool, '256', "Failed to run normally: signal $signal");
	}
	if ($retval) {
		return report($testname, $tool, $retval, "Failed to detect error: retval $retval");
	}
	return report($testname, $tool, '0');
	
}

sub report {
	my ($test, $name, $result, $msg) = (@_);
	my $elapsed = tv_interval($_timer, [gettimeofday]);
	printf("%-74s\t%s\t%-10s\t%.3f\t%s\n", $test, $name, $result, $elapsed, $msg);
}

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