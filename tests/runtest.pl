#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);
use File::Basename;
use Text::Diff;
use XML::LibXML;
# use Unicode::Escape;
#use Encoding::FixLatin qw(fix_latin);
require Encode;
use Devel::Peek qw(Dump);


# use XML::Writer;

# first argument is a flag, -p or -f for shouldPass or shouldFail
# second argument is a directory to test
my $numArgs = $#ARGV + 1;
if ($numArgs != 2) {
      die "Not enough command line arguments"
}

my $kcc = "kcc";
#my $kcc = "ccomp -fbitfields -flonglong -fstruct-passing -fstruct-assign -fvararg-calls -dparse -dc";
#my $kcc = "ccomp -fbitfields -flonglong -fstruct-passing -fstruct-assign -fvararg-calls";
my $gcc = "gcc -lm -Wall -Wextra -x c -O0 -m32 -U __GNUC__ -pedantic -std=c99";

my $flag = $ARGV[0];
my $shouldFail = 0;
# this is so terrible...
my $shouldRun = 0;
if ($flag eq "-f") {
      $shouldFail = 1;
} elsif ($flag eq "-p"){
#$shouldFail = 0;
} elsif ($flag eq "-r"){
      $shouldRun = 1;
} else {
      die "use either -f or -p";
}
my $directory = $ARGV[1];
my $testSuite = $directory;
if ($testSuite eq "gcc-torture") {
      $shouldRun = 1;
}
my $outputFilename = "results-$directory.xml";

my $globalTests = "";
my $globalNumPassed = 0;
my $globalNumFailed = 0; # failures are tests that ran but failed
my $globalNumError = 0; # errors are tests that didn't finish running
my $globalTotalTime = 0;

my @files = <$directory/*>;
my %partOfSet;
my @allFilenames = ();
foreach my $fullFilename (@files) {
      my ($baseFilename, $dirname, $suffix) = fileparse($fullFilename,".c");
      if ($suffix ne '.c') { next; }
      if ($baseFilename =~ m/^(.*)-link\d+$/) {
            $baseFilename = $1;
            if ($partOfSet{$baseFilename}) { next; }
            $partOfSet{$baseFilename} = 1;
      }
      @allFilenames = getMatchingFiles($baseFilename, @files);
      my $filename = "$baseFilename";
      performTest($dirname, $baseFilename, @allFilenames);
}
open(OUT, ">$outputFilename"); #open for write, overwrite
# binmode OUT, ':utf8';
print OUT "<?xml version='1.0' encoding='UTF-8' ?>\n";
print OUT "<testsuite name='$testSuite' time='$globalTotalTime'>\n";
# Dump $globalTests;
# utf8::downgrade($globalTests);
# utf8::downgrade($globalTests);
# my $utf8_string = fix_latin($globalTests);
# $globalTests =~ s/([^\x00-\x7f])/foo/g;
# sprintf("&#%d;", ord($1))
# $globalTests =~ s/./foo/g;
# $globalTests = "";
# my $utf8_string = Encode::decode('utf8', $globalTests, 6);
my $utf8_string = $globalTests;
print OUT "$utf8_string";
print OUT "</testsuite>\n";
close OUT;

sub getMatchingFiles {
      my ($pattern, @files) = (@_);

      my @matchingFiles = ();
      foreach my $fullFilename (@files) {
            my ($baseFilename, $dirname, $suffix) = fileparse($fullFilename,".c");
            if ($suffix ne '.c') { next; }
            if ($baseFilename =~ /^$pattern$/) {
                  push(@matchingFiles, "$dirname$baseFilename.c");
                  last;
            }
            if ($baseFilename =~ /^$pattern-link\d+$/) {
                  push(@matchingFiles, "$dirname$baseFilename.c");
            }
      }
      return @matchingFiles;
}

sub performTest {
      my ($dirname, $baseFilename, @allFilenames) = (@_);
      my $testName = "$dirname$baseFilename.c";
      #print "dirname=$dirname\n";
      #print "baseFilename=$baseFilename\n";
      my $kccFilename = "${dirname}test-$baseFilename.kcc";
      my $gccFilename = "${dirname}test-$baseFilename.gcc";
      my $allFiles = join(' ',@allFilenames);
      my $timer = [gettimeofday];

      my $kccCompileOutput = `$kcc -o $kccFilename $allFiles 2>&1`;
      my $kccCompileRetval = $?;
      # my $encodedOut = HTML::Entities::encode_entities($kccCompileOutput);

      print "$testName\t";

      my $lookForError=0;
      if ($#allFilenames == 0) { # no logic to make this work for multiple translation units
            open(TEST, "<$testName") or return reportFailure($testName, $timer, "Failure---could not open $testName for reading.");
            while(my $line = <TEST>){
                  chomp($line);
                  if ($line =~ /kcc-assert-error\((\d+)\)/) {
                        $lookForError = $1;
                        last;
                  }
            }
            close(TEST);
      }

      if ($kccCompileRetval) {
            if ($shouldFail) {
                  if ($lookForError && !($kccCompileOutput =~ /Error $lookForError/m)) {
                        return reportFailure($testName, $timer, "Failure---Was expecting particular error message but failed to compile");
                  }
                  return reportSuccess($testName, $timer, "Success---didn't compile with kcc. \n\n$kccCompileOutput\n");
            } else {
                  return reportFailure($testName, $timer, "Failure---kcc failed to compile $testName.\n\n$kccCompileOutput\n");
            }
      }

      my $gccCompileOutput = `$gcc -o $gccFilename $allFiles 2>&1`;
      my $gccCompileRetval = $?;
      #$encodedOut = HTML::Entities::encode_entities($gccCompileOutput);
      if ($gccCompileRetval) {
            if (!$shouldFail && !$shouldRun) {
                  return reportError($testName, $timer, "gcc failed to compile $testName.\n\n$gccCompileOutput\n");
            }
      }

      my $kccRunOutput = `timeout 45m $kccFilename 2>&1`;
      $kccRunOutput =~ s/^VOLATILE.*\n//mg;
      my $kccRunRetval = $?;
      if ($shouldFail) {
            # if ($kccRunRetval == 0) {
            if (!($kccRunOutput =~ /^ERROR!/m)) {
                  # my $encodedOut = HTML::Entities::encode_entities($kccRunOutput);
                  return reportFailure($testName, $timer, "Failure---Program seemed to run to completion. \n\n$kccRunOutput\n");
            } else {
                  if ($lookForError) {
                        if ($kccRunOutput =~ /^Error: $lookForError$/m) {
                              return reportSuccess($testName, $timer, "Success---Core dumped; Expected error $lookForError found");
                        } else {
                              return reportFailure($testName, $timer, "Failure---Program failed, but didn't give expected error message $lookForError");
                        }
                  }
                  return reportSuccess($testName, $timer, "Success---Core dumped. \n\n$kccRunOutput\n");
            }
      }

      # hack
      if ($shouldRun){
            if ($kccRunRetval != 0) {
                  my $msg = "";
                  # my $encodedOut = HTML::Entities::encode_entities($kccRunOutput);
                  $msg .= "kcc retval=$kccRunRetval\n";
                  $msg .= "-----------------------------------------------\n";
                  $msg .= "$kccRunOutput\n";
                  $msg .= "-----------------------------------------------\n";
                  return reportFailure($testName, $timer, $msg);
            } else {
                  return reportSuccess($testName, $timer, "Success");
            }
      }

      my $gccRunOutput = `$gccFilename 2>&1`;
      $gccRunOutput =~ s/^VOLATILE.*\n//mg;
      # print $gccRunOutput;
      my $gccRunRetval = $?;
      if (($kccRunRetval != $gccRunRetval) || ($kccRunOutput ne $gccRunOutput)) {
            my $msg = "Return values were not identical.\n";
            $msg .= "kcc retval=$kccRunRetval\n";
            $msg .= "gcc retval=$gccRunRetval\n";
            if ($kccRunOutput ne $gccRunOutput) {
                  $msg .= "Outputs were not identical.\n";
                  my $diff = diff(\$gccRunOutput, \$kccRunOutput, { STYLE => "Unified" });
                  # my $encodedDiff = HTML::Entities::encode_entities($diff);
                  # my $text = new XML::Code('=');
                  # $text->set_text($diff);
                  $msg .= "-----------------------------------------------\n";
                  $msg .= "$diff\n";
                  $msg .= "-----------------------------------------------\n";
                  #$msg .= "(actual output elided)\n";
            }
            return reportFailure($testName, $timer, $msg);
      }

      return reportSuccess($testName, $timer, "Success");
}

sub reportFailure {
      my ($name, $timer, $message) = (@_);
      $globalNumFailed++;
      $message = encode($message);
      $message =~ s/^Full report can be found in (.*)$/Full report can be found in <a href=\"$1\">$1<\/a>/m;
      my $inner = "<failure>$message</failure>";
      print "FAILED $message\n";
      return reportAny($name, $timer, $inner);      
}
sub reportError {
      my ($name, $timer, $message) = (@_);
      $globalNumError++;
      $message = encode($message);
      $message =~ s/^Full report can be found in (.*)$/Full report can be found in <a href=\"$1\">$1<\/a>/m;
      my $inner = "<error>$message</error>";
      print "errored\n";
      return reportAny($name, $timer, $inner);      
}
sub reportSuccess {
      my ($name, $timer, $message) = (@_);
      $globalNumPassed++;
      $message = encode($message);
      my $inner = "$message";
      print "passed\n";
      return reportAny($name, $timer, $inner);      
}

sub reportAny {
      my ($name, $timer, $inner) = (@_);
      my $elapsed = tv_interval( $timer, [gettimeofday]);
      $globalTotalTime += $elapsed;
      $globalTests .= "\t<testcase name='$name' time='$elapsed'>\n";
      $globalTests .= "\t\t<measurement><name>Time</name><value>$elapsed</value></measurement>\n";
      $globalTests .= "\t\t$inner\n";
      $globalTests .= "\t</testcase>\n";
}

sub encode {
      my ($str) = (@_);
      $str =~ s/([^\x00-\x7f])/sprintf("&#%d;", ord($1))/eg;
      my $doc = XML::LibXML::Document->new('1.0', 'UTF-8');
      my $node = $doc->createTextNode($str);
      return $node->toString();
}

#@diff -y --suppress-common-lines -I '^VOLATILE' $+

# output-%: test-%
# @echo "Running $< ..."
# @trap "" SIGABRT; $(COMMAND_PREFIX) ./$< 2>&1 > $@.tmp; RETURN_VALUE=$$?; echo $$RETURN_VALUE >> $@.tmp
# @mv $@.tmp $@

# <testcase classname="net.cars.engine.PistonTest" name="moveUp" time="0.022">
# <error message="test timed out after 1 milliseconds" type="java.lang.Exception">java.lang.Exception: test timed out after 1 milliseconds
# </error>
# </testcase>
# <testcase classname="net.cars.engine.PistonTest" name="moveDown" time="0.0010" />
# <testcase classname="net.cars.engine.PistonTest" name="checkStatus" time="0.0030">
# <failure message="Plunger status invalid to proceed driving." type="junit.framework.AssertionFailedError">junit.framework.AssertionFailedError: Plunger status invalid to proceed driving.
# at net.cars.engine.PistonTest.checkStatus(PistonTest.java:42)
# </failure>
# </testcase>
# <testcase classname="net.cars.engine.PistonTest" name="checkSpeed" time="0.0080">
# <failure message="Plunger upward speed below specifications." type="junit.framework.AssertionFailedError">junit.framework.AssertionFailedError: Plunger upward speed below specifications.
# at net.cars.engine.PistonTest.checkSpeed(PistonTest.java:47)
# </failure>
# </testcase>
# <testcase classname="net.cars.engine.PistonTest" name="lubricate" time="0.0030">
# <failure message="Failed to lubricate the plunger." type="junit.framework.AssertionFailedError">junit.framework.AssertionFailedError: Failed to lubricate the plunger.
# at net.cars.engine.PistonTest.lubricate(PistonTest.java:52)
# </failure>
# </testcase>
