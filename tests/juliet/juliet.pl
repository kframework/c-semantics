#! /usr/bin/env perl
use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use XML::LibXML;

my $childPid = 0;

# first argument is a flag, -p or -f for shouldPass or shouldFail
# second argument is a directory to test
my $numArgs = $#ARGV + 1;
if ($numArgs != 2) {
	die "Not enough command line arguments"
}

my $command = $ARGV[0];
my $test = $ARGV[1];

unlink "juliet.out";
if (-e "juliet.out") {
	print "couldn't remove juliet.out.  Failing\n";
	exit(1);
}

my ($signal, $retval, $output, $stderr);

($signal, $retval, $output, $stderr) = run("$command -x c -o juliet.out -std=c99 -pedantic -Wall -I testcasesupport -D INCLUDEMAIN -D _KCC_EXPERIMENTAL_TIME testcasesupport/io.c $test");

print "$output\n$stderr";
if ($signal) {
	print "signal $signal\n";
	exit 1;
}
if ($retval) {
	print "failed to compile: returned $retval\n";
	exit 2;
}

($signal, $retval, $output, $stderr) = run("./juliet.out");
print "$output\n$stderr\n";
if ($output =~ m/^Finished good\(\)$/m) {
	print "ran good\n";
} else {
	print "didn't run good\n";
	exit 3;
}
if ($output =~ m/^Finished bad\(\)$/m) {
	print "ran bad\n";
	exit 4;
} else {
	print "didn't run bad\n";
	#exit 1;
}

if ($signal) {
	print "signal $signal\n";
	exit 5;
}
if ($retval) {
	print "failed to run: returned $retval\n";
	exit 0;
}
print "didn't see any errors.  Failing test case\n";
exit 6;

sub run {
	my ($theircommand) = (@_);

	my $command = "./stdbuf -o0 -e0 $theircommand 1>stdout.txt 2>stderr.txt";
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
