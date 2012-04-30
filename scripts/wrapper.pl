use strict;
use File::Temp qw/ tempfile /;
use File::Spec::Functions qw(rel2abs);
use File::Basename;

sub maudeOutputWrapper {
	my ($plainOutput, $screenOutput, @input) = (@_);
	my $realOutput = "";
	my $state = "start";
	my $retval = -1;
	my $reduced = 0;
	my $haveResult = 0;
	my $buffer = "";
	my $haveError = 0;

	my $errorCell = "";
	my $finalComp = "";
	my $finalCompGoto = "";
	my $finalCompType = "";

	my $myFunc = "";
	my $myFile = "";
	my $myLine = "";
	my $myOffsetStart = "";
	my $myOffsetEnd = "";

	# my $kCell = "";
	# my $typeCell = "";
	# my $ignoreThis = 0;
	for my $line (@input) {
	#while (my $line = <STDIN>) {
		$buffer .= $line;
		chomp($line);
		#$line =~ s/[\000-\037]\[(\d|;)+m//g; # remove ansi colors
		#print "$line\n";
		if ($state eq "start"){
			if ($line =~ m/rewrites: /){
				$state = "rewrite";
				#printf "REWRITE\n";
			}
		} elsif ($state eq "rewrite"){
			#$line = <STDIN>;
			#$buffer .= $line;
			#$line =~ s/[\000-\037]\[(\d|;)+m//g; # remove ansi colors
			#print "$line\n";
			if ($line =~ m/^result (?:NeBag|Bag): (.*)$/){
				$state = "success";
				$realOutput .= $1;
				#printf "SUCCESS\n";
			} else {
				$state = "failure";
				$realOutput .= "FAILURE\n";
			}
		} elsif ($state eq "success"){
			# if ($line =~ m/< input > .* <\/ input >/){
				# $reduced = 1;
			# } elsif ($line =~ m/< unflushedOutput > # "(.*)"\(\.List{K}\) <\/ unflushedOutput >/){
				# my $output = $1;
				# $output =~ s/\%/\%\%/g;
				# $output =~ s/`/\\`/g;
				# $output =~ s/\\\\/\\\\\\\\/g;
				# $realOutput .= substr(`printf "x$output"`, 1);
			if ($line =~ m/< output > # "(.*)"\(\.List{K}\) <\/ output >/){
				$reduced = 1;
				my $output = $1;
				$output =~ s/\%/\%\%/g;
				$output =~ s/`/\\`/g;
				$output =~ s/\\\\/\\\\\\\\/g;
				$output = substr(`printf "x$output"`, 1);
				# print "have:\n$output\n";
				# print "looking for:\n$screenOutput\n";
				my $index = index($output, $screenOutput);
				if ($index == 0){
					$realOutput .= substr($output, length($screenOutput));
				} else {
					$realOutput .= "Internal Error: couldn't find stdout in semantic output\n";
				}
				#$realOutput .= substr(`printf "x$output"`, 1);
			} elsif ($line =~ m/< errorCell > # "(.*)"\(\.List{K}\) <\/ errorCell >/){
				$haveError = 1;
				my $output = $1;
				$output =~ s/\%/\%\%/g;
				$output =~ s/`/\\`/g;
				$output =~ s/\\\\/\\\\\\\\/g;
				$errorCell = substr(`printf "x$output"`, 1);
			} elsif ($line =~ m/< currentFunction > # Identifier\("(.*)"\)\(\.List\{K\}\) <\/ currentFunction >/) {
				$myFunc = $1;
			} elsif ($line =~ m/< currentProgramLoc > \('CabsLoc\)\.KLabel\(# "(.*)"\(\.List\{K\}\),,# (\d+)\(\.List\{K\}\),,# (\d+)\(\.List\{K\}\),,# (\d+)\(\.List\{K\}\)\) <\/ currentProgramLoc >/) {
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
			} elsif ($line =~ m/< computation > (.*) <\/ computation >/){
				$haveError = 1;
				$finalCompGoto = $1;
			} elsif ($line =~ m/< type > (.*) <\/ type >/){
				$haveError = 1;
				$finalCompType = $1;
			} elsif ($line =~ m/< resultValue > \('tv\)\.KLabel\(kList\("List`{K`}2K_"\)\(# (-?\d+)\(\.List\{K\}\)\),,\('t\)\.KLabel\(Set2KLabel \.\(\.List\{K\}\),,\('int\)\.KLabel\(\.List\{K\}\)\)\) <\/ resultValue >/){
				$haveResult = 1;
				$retval = $1;
			}
		}
		
		if ($state eq "failure"){
			$realOutput .= "$line\n";
		}
	}
	if ($plainOutput) {
		$realOutput .= "$buffer\n";
	} elsif ($reduced == 0 || $haveResult == 0) {
		#print "$buffer\n";
		$realOutput .= "\n=============================================================\n";
		$realOutput .= "ERROR! KCC encountered an error while executing this program.\n";
		my $baseName = fileparse($myFile);
		my $template = "kcc-dump-$baseName-XXXXXXXXXX";
		my ($fh, $filename) = tempfile($template, SUFFIX => '.kdump');
		print $fh "$buffer\n";
		if ($errorCell ne "") {
			$realOutput .= "=============================================================\n";
			$realOutput .= "$errorCell\n";
		}
		$realOutput .= "=============================================================\n";
		$realOutput .= "File: $myFile\n";
		$realOutput .= "Function: $myFunc\n";
		$realOutput .= "Line: $myLine\n";
		#print "Possible offset into line: $myOffsetStart\n";
		if ($finalComp ne "") {
			$realOutput .= "=============================================================\n";
			$realOutput .= "Final Computation:\n";
			$realOutput .= substr($finalComp, 0, 1000);
			$realOutput .= "\n";
		}
		if ($finalCompGoto ne "") {
			$realOutput .= "=============================================================\n";
			$realOutput .= "Final Goto Map Computation:\n";
			$realOutput .= substr($finalCompGoto, 0, 1000);
			$realOutput .= "\n";
		}
		if ($finalCompType ne "") {
			$realOutput .= "=============================================================\n";
			$realOutput .= "Final Type Computation:\n";
			$realOutput .= substr($finalCompType, 0, 1000);
			$realOutput .= "\n";
		}
		
		
		$realOutput .= "\nFull report can be found in $filename\n";
		close $fh;
	}
	return ($retval, $realOutput);
}
1;
