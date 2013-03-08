#!/usr/bin/env perl
my $kcc = $ARGV[0];
my $filename = $ARGV[1];
my $compiled = $ARGV[2];

my $testProgram1 = "#include <stdio.h>\nint main(void) {printf(\"x\"); return 42;}\n";

aTest($testProgram1, 42, "x");
#aTest($testProgram2, 1, "yz");

#############################################################

sub aTest {
	my ($testProgram, $expectedValue, $expectedOutput) = (@_);
	
	open($fh, ">$filename") or die "Couldn't open $filename";
	print $fh $testProgram;
	close($fh);
	print "Running: $kcc -o $compiled $filename...\n";
	system("$kcc -o $compiled $filename") == 0
		or die "There was a problem compiling the test program.  The return value from kcc was: $?";

	open P,"$compiled |" or die "Error running compiled program!";
	my @data=<P>;
	close P;
	my $actualValue = $? >> 8;

	if ($actualValue != $expectedValue) {
		die "Error in return value from compiled program.  I expected $expectedValue, but got $actualValue.\nOutput was:\n@data\n";
	}
	print "Return value is correct.\n";
	my $actualOutput = join("", @data);
	if ($actualOutput ne $expectedOutput) {
		die "Error in output from compiled program.  I expected:\n$expectedOutput\nbut I saw:\n$actualOutput\n";
	}
	print "Output is correct.\n";
}