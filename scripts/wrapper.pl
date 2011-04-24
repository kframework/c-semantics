use strict;
use File::Temp qw/ tempfile /;
use File::Spec::Functions qw(rel2abs);
use File::Basename;
my $distDir = dirname(rel2abs($0));
my $outputFilter = "filterOutput";

my $plainOutput = 0;
my $numArgs = $#ARGV + 1;
if ($numArgs > 0) {
	$plainOutput = $ARGV[0];
}

my $state = "start";
my $retval = -1;
my $reduced = 0;
my $haveResult = 0;
my $buffer = "";
my $haveError = 0;

my $errorCell = "";
my $finalComp = "";

my $myFunc = "";
my $myFile = "";
my $myLine = "";
my $myOffsetStart = "";
my $myOffsetEnd = "";

# my $kCell = "";
# my $typeCell = "";
# my $ignoreThis = 0;
while (my $line = <STDIN>) {
	# if (!$ignoreThis){
	$buffer .= $line;
	# }
	chomp($line);
	$line =~ s/[\000-\037]\[(\d|;)+m//g; # remove ansi colors
	#print "$line\n";
	if ($state eq "start"){
		if ($line =~ m/^erewrite in /){
			$state = "rewrite";
			#printf "REWRITE\n";
		}
	} elsif ($state eq "rewrite"){
		$line = <STDIN>;
		$buffer .= $line;
		$line =~ s/[\000-\037]\[(\d|;)+m//g; # remove ansi colors
		#print "$line\n";
		if ($line =~ m/^result NeBag:/){
			$state = "success";
			#printf "SUCCESS\n";
		} else {
			$state = "failure";
			printf "FAILURE\n";
		}
	} elsif ($state eq "success"){
		if ($line =~ m/< input > .* <\/ input >/){
			$reduced = 1;
		} elsif ($line =~ m/< output > String "(.*)"\(\.List{K}\) <\/ output >/){
			my $output = $1;
			$output =~ s/\%/\%\%/g;
			$output =~ s/\\\\/\\\\\\\\/g;
			print substr(`printf "x$output"`, 1);
		} elsif ($line =~ m/< errorCell > String "(.*)"\(\.List{K}\) <\/ errorCell >/){
			$haveError = 1;
			my $output = $1;
			$output =~ s/\%/\%\%/g;
			$output =~ s/\\\\/\\\\\\\\/g;
			$errorCell = substr(`printf "x$output"`, 1);
		} elsif ($line =~ m/< currentFunction > Id Identifier\("(.*)"\)\(\.List\{K\}\) <\/ currentFunction >/) {
			$myFunc = $1;
		} elsif ($line =~ m/< currentProgramLoc > \('CabsLoc\)\.KProperLabel\(String "(.*)"\(\.List\{K\}\),,Rat (\d+)\(\.List\{K\}\),,Rat (\d+)\(\.List\{K\}\),,Rat (\d+)\(\.List\{K\}\)\) <\/ currentProgramLoc >/) {
			$myFile = $1;
			$myLine = $2;
			$myOffsetStart = $3;
			$myOffsetEnd = $4;
		} elsif ($line =~ m/< finalComputation > (.*) <\/ finalComputation >/){
			$haveError = 1;
			$finalComp = $1;
		} elsif ($line =~ m/< k > (.*) <\/ k >/){
			$haveError = 1;
			$finalComp = $1;
		} elsif ($line =~ m/< resultValue > \('tv\)\.KResultLabel\(kList\("wklist_"\)\(Rat (-?\d+)\(\.List\{K\}\)\),,\('int\)\.KResultLabel\(\.List\{K\}\)\) <\/ resultValue >/){
			$haveResult = 1;
			$retval = $1;
		}
	}
	
	if ($state eq "failure"){
		print "$line\n";
	}
}
if ($reduced == 0||$haveResult == 0) {
	#print "$buffer\n";
	if ($plainOutput) {
		print "$buffer\n";
	} else {
		print "=============================================================\n";
		print "ERROR! KCC encountered an error while executing this program.\n";
		my $baseName = fileparse($myFile);
		my $template = "kcc-dump-$baseName-XXXXXXXXXX";
		my ($fh, $filename) = tempfile($template, SUFFIX => '.kdump');
		print $fh "$buffer\n";
		#my $filterOut =  `$distDir/$outputFilter $filename $distDir/outputFilter.yml`;
		if ($errorCell ne "") {
			print "=============================================================\n";
			print "$errorCell\n";
		}
		print "=============================================================\n";
		print "File: $myFile\n";
		print "Function: $myFunc\n";
		print "Line: $myLine\n";
		print "Possible offset into line: $myOffsetStart\n";
		if ($finalComp ne "") {
			print "=============================================================\n";
			print "Final Computation:\n";
			print substr($finalComp, 0, 1000);
			print "\n";
		}
			
		# < currentFunction > Id File-Scope(.List{K}) </ currentFunction >
		# < currentProgramLoc > ('CabsLoc).KProperLabel(String "challenge01.prepre.gen"(.List{K}),,Rat 1(.List{K}),,Rat 96(.List{K}),,Rat 1(.List{K})) 
		
		print "\nFull report can be found in $filename\n";
		close $fh;
	}
}
exit $retval;
