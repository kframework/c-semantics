#!/usr/bin/env perl
use strict;
use DBI;
my $RULE_LENGTH = 300;
my $numArgs = $#ARGV + 1;
# terrible hack :(
my $dbh = DBI->connect("dbi:SQLite:dbname=maudeProfileDBfile.sqlite","",""); #maudeProfileDBfile.sqlite

printData();
$dbh->disconnect;
exit 0;

sub printField {
	my ($s) = (@_);
	print "\t\"$s\"";
}

sub printData {
	# my $sth = $dbh->prepare("
	# SELECT 
		# --- data.runName
		# rules.ruleName
		# , data.rule
		# , rules.kind
		# --- , SUM(data.matches) as matches
		# --- , SUM(data.rewrites) as rewrites
		# , SUM(IFNULL(data.matches, 0)) as matches
		# , SUM(IFNULL(data.rewrites, 0)) as rewrites
		# , rules.locationFile
		# , rules.locationFrom
		# , rules.locationTo
	# FROM rules
	# LEFT OUTER JOIN (
		# SELECT * FROM data WHERE runName NOT LIKE 'tmpSemanticCalibration'
	# ) data ON
		# data.locationFile = rules.locationFile
		# AND data.locationFrom = rules.locationFrom
		# AND data.locationTo = rules.locationTo
		# AND data.kind = rules.kind
	# --- WHERE data.runName NOT LIKE 'tmpSemanticCalibration'
	# --- WHERE rules.isLibrary = 0
	# GROUP BY 
		# rules.locationFile
		# , rules.locationFrom
		# , rules.locationTo
		# , rules.kind
	# ORDER BY
		# matches DESC
	# ") or die $dbh->errstr;
	my $sth = $dbh->prepare("
	SELECT 
		ruleName
		, rule
		, kind
		, SUM(matches) as matches
		, SUM(rewrites) as rewrites
		, locationFile
		, locationFrom
		, locationTo
	FROM data
	WHERE runName NOT LIKE 'tmpSemanticCalibration'
	GROUP BY 
		locationFile
		, locationFrom
		, locationTo
		, kind
	ORDER BY
		matches DESC
	") or die $dbh->errstr;

	$sth->execute();
	# Fragment, Initial Tries, Resolve Tries, 
	print "RuleName\tLocation\tLineFrom\tLineTo\tKind\tMatches\tRewrites\tRule\n";
	while (my $hash_ref = $sth->fetchrow_hashref) {
		my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		$rule =~ s/[\n\t\r]/ /g; # turn newlines into spaces
		#$rule =~ s/["]/""/g; # escape quotes
		$rule =~ s/["]//g; # remove quotes
		$rule =~ s/[']//g; # remove quotes
		# print "\"$hash_ref->{runName}\"";
		print "\"$hash_ref->{ruleName}\"";
		# printField $hash_ref->{ruleName};
		printField $hash_ref->{locationFile};
		printField $hash_ref->{locationFrom};
		printField $hash_ref->{locationTo};
		printField $hash_ref->{kind};
		printField $hash_ref->{matches};
		printField $hash_ref->{rewrites};
		printField $rule;
		print "\n";
		# $fragment, $initialTries, $resolveTries, 
	}
}
# sub printCount {
	# my $sth = $dbh->prepare("
	# SELECT count(distinct a.rule) as count
	# FROM data a
	# WHERE a.type != 'op'
	# AND (a.kind != 'macro' 
	# OR (a.kind == 'macro' AND (a.rule LIKE '%structural%' or a.rule LIKE '%computational%')))
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# print "Rule, Count, Kind, Matches, Rewrites\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# # my $file = $hash_ref->{file};
		# # my $type = $hash_ref->{type};
		# my $count = $hash_ref->{count};
		# # my $kind = $hash_ref->{kind};
		# # my $suite = $hash_ref->{suite};
		# # my $rewrites = $hash_ref->{rewrites};
		# # my $matches = $hash_ref->{matches};
		# # my $fragment = $hash_ref->{fragment};
		# # my $initialTries = $hash_ref->{initialTries};
		# # my $resolveTries = $hash_ref->{resolveTries};
		# # my $successes = $hash_ref->{successes};
		# # my $failures = $hash_ref->{failures};
		# # print "\"$rule\"\n";
		# print "$count\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }

# sub printCommonRules {
	# my $sth = $dbh->prepare("
	# SELECT b.rule as rule, b.count as count, b.rewrites as rewrites
	# from (SELECT a.rule, count(file) as count, sum(rewrites) as rewrites
		# FROM data a
		# WHERE a.type != 'op' 
		# --- AND suite == 'gcc'
		# AND (a.kind != 'macro'
			# OR (a.kind == 'macro' AND (a.rule LIKE '%structural%' or a.rule LIKE '%computational%'))
			# )
		# GROUP BY a.rule
	# ) b
	# --- where b.count >= 50
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# # print "Rule\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# $rule = "\"$rule\"";
		# my $count = $hash_ref->{count};
		# my $rewrites = $hash_ref->{rewrites};
		# print "$rule, $count, $rewrites\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }
# sub printLabels {
# # update data set rule = replace(rule, '(k).CellLabel', 'k')
	# # --- SELECT replace(a.rule, '(k).CellLabel', 'k') as new
	# # --- FROM data a
	# # WHERE rule like '%(k).CellLabel%'
	# # --- GROUP BY new
	# my $sth = $dbh->prepare("
	# SELECT rule 
	# FROM data a
	# WHERE rule like '%.CellLabel%'
	# --- UPDATE data SET rule = replace(rule, '(T).CellLabel', 'T')
	# --- WHERE rule like '%(T).CellLabel%'
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# print "Rule\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# $rule = "\"$rule\"";
		# # my $new = $hash_ref->{new};
		# # my $rewrites = $hash_ref->{rewrites};
		# print "$rule\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }
# sub printLib {
# # update data set rule = replace(rule, '(k).CellLabel', 'k')
	# # --- SELECT replace(a.rule, '(k).CellLabel', 'k') as new
	# # --- FROM data a
	# # WHERE rule like '%(k).CellLabel%'
	# # --- GROUP BY new
	# my $sth = $dbh->prepare("
	# SELECT rule, file
	# FROM data a
	# WHERE rule like 'calloc%'
	# --- UPDATE data SET rule = replace(rule, '(T).CellLabel', 'T')
	# --- WHERE rule like '%(T).CellLabel%'
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# print "Rule\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# $rule = "\"$rule\"";
		# my $file = $hash_ref->{file};
		# # my $rewrites = $hash_ref->{rewrites};
		# print "$file, $rule\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }

# sub printFileInfo {
	# my $sth = $dbh->prepare("
	# SELECT a.file, count(a.rule) as count,
	# sum(a.rewrites) as rewrites, SUM(a.matches) as matches
	# FROM data a
	# WHERE a.type != 'op' AND a.kind != 'macro'
	# GROUP BY a.file
	# ORDER BY a.file
	# --- , a.type, a.kind
	# --- ORDER BY a.matches DESC
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# print "File, Count, Rewrites, Matches\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# my $file = $hash_ref->{file};
		# # my $type = $hash_ref->{type};
		# my $count = $hash_ref->{count};
		# # my $kind = $hash_ref->{kind};
		# my $rewrites = $hash_ref->{rewrites};
		# my $matches = $hash_ref->{matches};
		# print "$file, $count, $rewrites, $matches\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }




# sub printData {
# # SELECT a.file, a.rule, a.type, a.kind, SUM(a.rewrites), 
		# # SUM(a.matches), SUM(a.fragment), SUM(a.initialTries), 
		# # SUM(a.resolveTries), SUM(a.successes), SUM(a.failures)
	# my $sth = $dbh->prepare("
	# SELECT count(a.file) as count, a.rule, a.kind, 
	# sum(a.rewrites) as rewrites, SUM(a.matches) as matches
	# FROM data a
	# WHERE a.type != 'op' AND a.kind != 'macro'
	# GROUP BY a.rule
	# --- , a.type, a.kind
	# --- ORDER BY a.matches DESC
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# print "Rule, Count, Kind, Matches, Rewrites\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# # my $file = $hash_ref->{file};
		# # my $type = $hash_ref->{type};
		# my $count = $hash_ref->{count};
		# my $kind = $hash_ref->{kind};
		# my $rewrites = $hash_ref->{rewrites};
		# my $matches = $hash_ref->{matches};
		# # my $fragment = $hash_ref->{fragment};
		# # my $initialTries = $hash_ref->{initialTries};
		# # my $resolveTries = $hash_ref->{resolveTries};
		# # my $successes = $hash_ref->{successes};
		# # my $failures = $hash_ref->{failures};
		# print "\"$rule\", $count, $kind, $matches, $rewrites\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }

# sub printFileInfo {
	# my $sth = $dbh->prepare("
	# SELECT a.file, count(a.rule) as count,
	# sum(a.rewrites) as rewrites, SUM(a.matches) as matches
	# FROM data a
	# WHERE a.type != 'op' AND a.kind != 'macro'
	# GROUP BY a.file
	# ORDER BY a.file
	# --- , a.type, a.kind
	# --- ORDER BY a.matches DESC
	# ") or die $dbh->errstr;
	# $sth->execute();
	# # Fragment, Initial Tries, Resolve Tries, 
	# print "File, Count, Rewrites, Matches\n";
	# while (my $hash_ref = $sth->fetchrow_hashref) {
		# my $rule = substr($hash_ref->{rule}, 0, $RULE_LENGTH);
		# $rule =~ tr{\n}{ }; # turn newlines into spaces
		# $rule =~ s/["]/""/g; # escape quotes
		# my $file = $hash_ref->{file};
		# # my $type = $hash_ref->{type};
		# my $count = $hash_ref->{count};
		# # my $kind = $hash_ref->{kind};
		# my $rewrites = $hash_ref->{rewrites};
		# my $matches = $hash_ref->{matches};
		# print "$file, $count, $rewrites, $matches\n";
		# # $fragment, $initialTries, $resolveTries, 
	# }
	# $dbh->disconnect();
# }