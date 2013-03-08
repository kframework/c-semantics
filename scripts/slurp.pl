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
	#print STDERR "slurping $incomingFile\n";
	my ($baseName, $path, $suffix) = fileparse($incomingFile, '.maude');
	if ($suffix eq "") {
		$suffix = ".maude";
	}
	$baseName = "$baseName$suffix";
	#print "$baseName\n";
	if (-e catfile($path, $baseName)) {
		return slurpRead($path, $baseName);
	} elsif (-e catfile($incomingPath, $baseName)) {
		return slurpRead($incomingPath, $baseName);
	} else {
		print STDERR "Couldn't find file " . catfile($path, $baseName) . "\n";
		print STDERR "Couldn't find file " . catfile($incomingPath, $baseName) . "\n";
		die "Couldn't fine any files\n";
	}

	#my ($filename, $dirname, $suffix) = fileparse($file, ".maude");
	
}

sub slurpRead {
	my ($path, $filename) = (@_);
	my $file = catfile($path, $filename);
	my $retval = "--- slurping $filename\n";
	#print "opening $filename\n";
	open(my $fh, "<$file") or die "Couldn't open file $file\n";
	while (my $line = <$fh>) {
		chomp($line);
		#print STDERR "$filename: $line\n";
		if ($line =~ m/^\s*load\s*"?([^\s"]*)"?\s*$/) {
			my $newFile = $1;
			#print STDERR "Slurping $newFile\n";
			$retval .= slurpFindFile($path, $newFile);
			#print STDERR "Returning from $newFile\n";
			#print STDERR "at location " . tell($fh) . "\n";
		} else {
			$retval .= "$line\n";
		}
	}
	close(NEWFILE);
	return "$retval\n";

}

1;