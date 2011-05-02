use strict;
use File::Basename;
use File::Spec::Functions qw(rel2abs catfile);

sub slurp {
	my (@base) = (@_);
	my $retval = "";
	if (scalar(@base) == 0) {
		die "No files passed to slurp\n";
	}
	foreach my $file (@base) {
		$retval .= slurpFindFile('./', $file);
	}
	return $retval;
}

sub slurpFindFile {
	my ($incomingPath, $incomingFile) = (@_);
	
	my ($baseName, $path, $suffix) = fileparse($incomingFile, '.maude');
	if ($suffix eq "") {
		$suffix = ".maude";
	}
	$baseName = "$baseName$suffix";
	if (-e catfile($path, $baseName)) {
		return slurpRead($path, $baseName);
	} elsif (-e catfile($incomingPath, $baseName)) {
		return slurpRead($incomingPath, $baseName);
	} else {
		print "Couldn't find file " . catfile($path, $baseName) . "\n";
		print "Couldn't find file " . catfile($incomingPath, $baseName) . "\n";
		die "Couldn't fine any files\n";
	}

	#my ($filename, $dirname, $suffix) = fileparse($file, ".maude");
	
}

sub slurpRead {
	my ($path, $filename) = (@_);
	my $file = catfile($path, $filename);
	my $retval = "";
	#print "opening $filename\n";
	open(NEWFILE, $file) or die "Couldn't open file $file\n";
	while (my $line = <NEWFILE>) {
		chomp($line);
		#print "$line\n";
		if ($line =~ m/^\s*load\s*"?([^\s"]*)"?\s*$/) {
			$retval .= slurpFindFile($path, $1);
		} else {
			$retval .= "$line\n";
		}
	}
	close(NEWFILE);
	return "$retval\n";

}

1;