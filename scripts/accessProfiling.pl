#!/usr/bin/env perl
use strict;
use DBI;
my $RULE_LENGTH = 300;
my $dbh = DBI->connect("dbi:SQLite:dbname=maudeProfileDBfile.sqlite","",""); #maudeProfileDBfile.sqlite
my $query = join(" ", <>); # read from stdin or filename passed to script
printResults($query);

$dbh->disconnect;
exit 0;

sub printField {
	my ($s) = (@_);
	return "\t\"$s\"";
}

sub printPerFile {
	my ($filename) = (@_);

}

sub printResults {
	my ($query) = (@_);

	my $sth = $dbh->prepare($query) or die $dbh->errstr;
	$sth->execute();
	
	my $hash_ref = $sth->fetchrow_hashref;
	{
		my @fields = ();
		foreach my $key ( sort fieldOrder keys %$hash_ref ) {
			push(@fields, "\"$key\"");
		}
		print join("\t", @fields);
		print "\n";
	}
	
	do {
		my @fields = ();
		foreach my $key ( sort fieldOrder keys %$hash_ref ) {
			if ($key eq 'rule') {
				my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
				$rule =~ s/[\n\t\r]/ /g; # turn newlines into spaces
				$rule =~ s/["]//g; # remove quotes
				$hash_ref->{$key} = $rule;
			}
			push(@fields, "$hash_ref->{$key}");
		}
		print join("\t", @fields);
		print "\n";
	} while ($hash_ref = $sth->fetchrow_hashref);
}

sub fieldOrder {
	my %sorting = (x => 0
		, runName => 0
		, runNum => 5
		, ruleName => 10
		, locationFile => 15
		, locationFrom => 20
		, locationTo => 25
		, type => 35
		, kind => 40
		, matches => 45
		, rewrites => 50
		, rule => 100
	);
	if (exists $sorting{$a} and exists $sorting{$b}){
		$sorting{$a} <=> $sorting{$b};
	} else {
		$a cmp $b;
	}
}
