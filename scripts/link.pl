use strict;
use File::Basename;

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

	$retval .= "'Program(";
	$retval .= "'klist(_`(_`)(KList2KLabel_(";
	$retval .= printNested(@programs);
	$retval .= '), .KList))';
	$retval .= ')';
	return $retval;
}

sub linkFile {
	my (@contents) = (@_);
	foreach my $line (@contents){
            push(@programs, $line);
	}
}

sub printNested {
	my ($name, @rest) = (@_);

	if (defined($name)) {
		return "_`,`,_(($name), " . printNested(@rest) .")";
	} else {
		return '.KList';
	}
}

1;
