use strict;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use XML::LibXML;

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
assertContains("basicIO", run("$kcc adhoc/io.c -o adhoc.o && ./adhoc.o"), "helloworld32");
assertContains("OOB", run("$kcc adhoc/shortArray.c -o adhoc.o && ./adhoc.o"), "Error: 00002");

run("$kcc -c adhoc/twofile-link1.c");
run("$kcc -c adhoc/twofile-link2.c");
assertContains("twofiles", run("$kcc twofile-link1.o twofile-link2.o -o adhoc.o && ./adhoc.o"), 'f(2, 3)==7');

assertContains("cmdLineArgs", run("$kcc adhoc/sumn.c -o adhoc.o && ./adhoc.o 5"), "sum(5)==15");
assertContains("stdin", run("$kcc adhoc/stdin.c -o adhoc.o && echo \"hi.\" | ./adhoc.o"), "hxix.x");

assertContains("Ddefines", run("$kcc adhoc/defines.c -DFOO -DBAR -DBAZ=32 -o defines.o && ./defines.o"), "1321");
assertContains("Iincludes", run("$kcc -Iadhoc/inc adhoc/needsInclude.c -o includes.o && ./includes.o"), "xx0xx");

assertEquals("blank", run("$kcc adhoc/basic.c -o basic.o 2&>1 && ./basic.o 2&>1"), "");

assertContains("printfP", run("$kcc adhoc/percentP.c -o adhoc.o && ./adhoc.o"), "[sym(threadId(1) +Nat 0) + 0]");

assertContains("assert", run("$kcc adhoc/assert.c -o adhoc.o && ./adhoc.o"), "Assertion failed: `6 == 7'");

run("$kcc -c adhoc/three-link1.c");
run("$kcc -c adhoc/three-link2.c");
run("$kcc -c adhoc/three-link3.c");
run("ar -cvq libthree.a three-link2.o three-link3.o");
assertContains("archive", run("$kcc three-link1.o libthree.a -o adhoc.o && ./adhoc.o"), '15');



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
	
	if (index($haystack, $needle) >= 0) {
		return reportSuccess($testName, $elapsed, "Success");
	} else {
		my $msg = "Failure---could not find \"$needle\"\n";
		$msg .= "Instead found $haystack\n";
		return reportFailure($testName, $elapsed, $msg);
	}
}

sub assertEquals {
	my ($testName, $elapsed, $haystack, $needle) = (@_);
	
	if ($haystack eq $needle) {
		return reportSuccess($testName, $elapsed, "Success");
	} else {
		my $msg = "Failure---could not find \"$needle\"\n";
		$msg .= "Instead found:\n$haystack\n";
		return reportFailure($testName, $elapsed, $msg);
	}
}

sub reportFailure {
	my ($name, $timer, $message) = (@_);
	$globalNumFailed++;
	$message = encode($message);
	$message =~ s/^Full report can be found in (.*)$/Full report can be found in <a href=\"\1\">\1<\/a>/m;
	my $inner = "<failure>$message</failure>";
	print "$name failed\n";
	return reportAny($name, $timer, $inner);
}
sub reportError {
	my ($name, $timer, $message) = (@_);
	$globalNumError++;
	$message = encode($message);
	$message =~ s/^Full report can be found in (.*)$/Full report can be found in <a href=\"\1\">\1<\/a>/m;
	my $inner = "<error>$message</error>";
	print "$name errored\n";
	return reportAny($name, $timer, $inner);	
}
sub reportSuccess {
	my ($name, $timer, $message) = (@_);
	$globalNumPassed++;
	$message = encode($message);
	my $inner = "$message";
	print "$name passed\n";
	return reportAny($name, $timer, $inner);	
}

sub reportAny {
	my ($name, $timer, $inner) = (@_);
	my $elapsed = $timer;
	$globalTotalTime += $elapsed;
	$globalTests .= "\t<testcase name='$name' time='$elapsed'>\n";
	#$globalTests .= "\t\t<measurement><name>Time</name><value>$elapsed</value></measurement>\n";
	$globalTests .= "\t\t$inner\n";
	$globalTests .= "\t</testcase>\n";
}

sub encode {
	my ($str) = (@_);
	my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
	my $node = $doc->createTextNode($str);
	return $node->toString();
}
