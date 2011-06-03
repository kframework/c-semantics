use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use HTML::Entities;

# my $doc = XML::LibXML:Document->new('1.0',$some_encoding);
# my $element = $doc->createElement($name);
# $element->appendText($text);
# $xml_fragment = $element->toString();
# $xml_document = $doc->toString();


my $kcc = "../dist/kcc";
my $gcc = "gcc -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99";

my $globalTests = "";
my $globalNumPassed = 0;
my $globalNumFailed = 0; # failures are tests that ran but failed
my $globalNumError = 0; # errors are tests that didn't finish running
my $globalTotalTime = 0;

my $testSuite = "adhoc";
my $outputFilename = "results-adhoc.xml";
###################################

assertContains("nondetSimple", run("$kcc adhoc/nondet.c -o adhoc.o && SEARCH=1 ./adhoc.o"), "1 solutions found");
assertContains("nondetABC", run("$kcc adhoc/nondet2.c -o adhoc.o && SEARCH=1 ./adhoc.o"), "6 solutions found");
assertContains("basicIO", run("$kcc adhoc/io.c -i -o adhoc.o && ./adhoc.o"), "helloworld32");
assertContains("OOB", run("$kcc adhoc/shortArray.c -i -o adhoc.o && ./adhoc.o"), "Error: 00002");

run("$kcc -c adhoc/twofile-link1.c");
run("$kcc -c adhoc/twofile-link2.c");
assertContains("twofiles", run("$kcc twofile-link1.o twofile-link2.o -o adhoc.o && ./adhoc.o"), 'f\(2\, 3\)==7');

assertContains("cmdLineArgs", run("$kcc adhoc/sumn.c -o adhoc.o && ./adhoc.o 5"), "sum\(5\)==15");
assertContains("stdin", run("$kcc adhoc/stdin.c -o adhoc.o && echo \"hi.\" | ./adhoc.o"), "hxix.x");


###################################

open(OUT, ">$outputFilename"); #open for write, overwrite
print OUT "<?xml version='1.0' encoding='UTF-8' ?>\n";
print OUT "<testsuite name='$testSuite' time='$globalTotalTime'>\n";
print OUT "$globalTests";
print OUT "</testsuite>\n";
close OUT;


###################################

sub run {
	my ($command) = (@_);
	my $timer = [gettimeofday];
	my $out = `$command`;
	my $elapsed = tv_interval($timer, [gettimeofday]);
	return ($elapsed, $out);
}

sub assertContains {
	my ($testName, $elapsed, $haystack, $needle) = (@_);
	
	if ($haystack =~ /$needle/) {
		return reportSuccess($testName, $elapsed, "Success");
	} else {
		return reportFailure($testName, $elapsed, "Failure---could not find \"$needle\"");
	}
}

sub reportFailure {
	my ($name, $timer, $message) = (@_);
	$globalNumFailed++;
	my $inner = "<failure>$message</failure>";
	print "$name failed\n";
	return reportAny($name, $timer, $inner);	
}
sub reportError {
	my ($name, $timer, $message) = (@_);
	$globalNumError++;
	my $inner = "<error>$message</error>";
	print "$name errored\n";
	return reportAny($name, $timer, $inner);	
}
sub reportSuccess {
	my ($name, $timer, $message) = (@_);
	$globalNumPassed++;
	my $inner = "$message";
	print "$name passed\n";
	return reportAny($name, $timer, $inner);	
}

sub reportAny {
	my ($name, $timer, $inner) = (@_);
	my $elapsed = $timer;
	$globalTotalTime += $elapsed;
	$globalTests .= "\t<testcase name='$name' time='$elapsed'>\n";
	$globalTests .= "\t\t<measurement><name>Time</name><value>$elapsed</value></measurement>\n";
	$globalTests .= "\t\t$inner\n";
	$globalTests .= "\t</testcase>\n";
}
