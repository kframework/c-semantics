use strict;
use File::Basename;

# my $numArgs = $#ARGV + 1;
# #$startingDir = $ARGV[0];
# if ($numArgs < 1) {
	# die "Need to provide file names to link\n";
# }

my @programNames;
my @programs;
my $formulae;

sub linker {
	my @files = (@_);
	my @operators;
	my $retval = "";
	if (scalar(@files) == 0) {
		die "No files passed to linker\n";
	}
	foreach my $filename (@files) {
		#print "$filename\n";
		my @contents;
		if ($filename =~ m/\.a$/) {
			@contents = `ar -p $filename`;
			if ($?) {
				die "Something went wrong when trying to unarchive $filename\n";
			}
		} else {
			open(my $newFile, $filename) or die "Couldn't open file $filename\n";
			@contents = <$newFile>;
		}
		linkFile(@contents);
	}

	# foreach my $operator (@operators){
		# $retval .= "$operator\n";
	# }

	foreach my $program (@programs){
		$retval .= "$program\n";
	}
	$retval .= "op 'formulae : -> KLabel .\n";
	$retval .= $formulae;

	$retval .= "op 'linked-program : -> KLabel .\n";
	$retval .= "eq 'linked-program(.List{K}) = ";
	$retval .= "'Program(";
	$retval .= "'List((_`(_`)(kList(\"List`{K`}2K_\"), (";
	$retval .= printNested(@programNames);
	$retval .= '))))';
	$retval .= ')';
	return "$retval.\n";
}

sub linkFile {
	my (@contents) = (@_);
	foreach my $line (@contents){
		if ($line =~ m/^eq Trans(.*?)=/) {
			push(@programNames, "Trans$1");
			push(@programs, $line);
		}
		# print "$line\n";
		if ($line =~ m/^eq 'LTLAnnotation(\([^=]*\)) = (.*)\.$/) {
			print "$1, $2\n";
			$formulae .= "eq 'LTLAnnotation$1 = $2 .\n";
		}
	}
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