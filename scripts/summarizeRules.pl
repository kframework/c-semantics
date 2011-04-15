#!/usr/bin/env perl
use strict;
use DBI;
my $dbh = DBI->connect("dbi:SQLite:dbname=maudeProfileDBfile.sqlite","",""); #maudeProfileDBfile.sqlite
printData();
$dbh->disconnect;
exit 0;

sub printField {
	my ($s) = (@_);
	print "\t\"$s\"";
}

sub printData {
	my $sth = $dbh->prepare("
	SELECT 
		locationFile
		, count(*) as count
	FROM rules
	GROUP BY
		rules.locationFile
	ORDER BY
		rules.locationFile
	") or die $dbh->errstr;

	$sth->execute();
	# Fragment, Initial Tries, Resolve Tries, 
	print "Location\tRuleCount\n";
	while (my $hash_ref = $sth->fetchrow_hashref) {
		print "\"$hash_ref->{locationFile}\"";
		printField $hash_ref->{count};
		print "\n";
	}
}
