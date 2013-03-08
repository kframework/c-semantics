use strict;
use File::Basename;
use File::Spec::Functions qw(rel2abs catfile);
my $count = 1;
while(<>) {
	my $line = $_;
	chomp($line);
	if ($line =~ /mod[ ]+C[ ]+is/) {
		print "$count";
		exit;
	}
	$count++;
}
print "0";