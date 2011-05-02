use strict;
use File::Basename;
# my $numArgs = $#ARGV + 1;
# #$startingDir = $ARGV[0];
# if ($numArgs < 1) {
	# die "Need to provide file names to link\n";
# }

sub linker {
	my @files = (@_);
	my @operators;
	my @programNames;
	my @programs;
	my $retval = "";
	if (scalar(@files) == 0) {
		die "No files passed to linker\n";
	}
	foreach my $filename (@files) {
		#print "$filename\n";
		open(my $newFile, $filename) or die "Couldn't open file $filename\n";

		while (my $line = <$newFile>){
			chomp($line);
			if ($line =~ m/^mod C-(program-.*) is including/) {
				# push(@programNames, "$1");
				next;
			}
			if ($line =~ m/^eq(.*?)=/) { # if we have an equation, we're done with operators
				push(@programNames, $1);
				push(@programs, $line);
				last;
			}
			push(@operators, $line);
		}
	}

	foreach my $operator (@operators){
		$retval .= "$operator\n";
	}

	foreach my $program (@programs){
		$retval .= "$program\n";
	}

	$retval .= "op linked-program : -> K .\n";
	$retval .= "eq linked-program = ";
	$retval .= "('Program).KProperLabel(";
	$retval .= "('_::_).KHybridLabel(";
	$retval .= printNested(@programNames);
	$retval .= ')';
	$retval .= ')';
	return "$retval.\n";
}

sub printNested {
	my ($name, @rest) = (@_);
	my $retval = "";
	
	$retval .=  "($name),, ";
	#print @rest;
	if ($name != @rest) {
		$retval .= printNested(@rest);
	} else {
		$retval .= '.List{K}';
	}
	return $retval;
}

# foreach my $name (@programNames){
	# print "$name ";
# }
1;