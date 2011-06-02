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
	my @formulae;
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
			# print $line;
			chomp($line);
			if ($line =~ m/^eq Trans(.*?)=/) { # if we have an equation, we're done with operators
				push(@programNames, "Trans$1");
				push(@programs, $line);
			}
			if ($line =~ m/^eq ltls =(.*)/) { # if we have an equation, we're done with operators
				push(@formulae, $1);
			}
		}
	}

	# foreach my $operator (@operators){
		# $retval .= "$operator\n";
	# }

	foreach my $program (@programs){
		$retval .= "$program\n";
	}
	$retval .= "op 'ltls : -> KProperLabel .\n";
	$retval .= "op 'formulae : -> KProperLabel .\n";
	$retval .= "eq 'ltls(.List{K}) = 'formulae(";
	$retval .= printNested(@formulae);
	$retval .= ") .\n";

	$retval .= "op 'linked-program : -> KProperLabel .\n";
	$retval .= "eq 'linked-program(.List{K}) = ";
	$retval .= "('Program).KProperLabel(";
	$retval .= "('_::_).KHybridLabel(";
	$retval .= printNested(@programNames);
	$retval .= ')';
	$retval .= ')';
	return "$retval.\n";
}

sub printNested {
	my ($name, @rest) = (@_);

	if (defined($name)) {
		return "($name),, " . printNested(@rest);
	} else {#arg
		return '.List{K}';
	}
}

# foreach my $name (@programNames){
	# print "$name ";
# }
1;