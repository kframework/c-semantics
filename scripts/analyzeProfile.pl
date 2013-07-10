#!/usr/bin/env perl
use strict;
use DBI;
my $RULE_LENGTH = 20;
my $numArgs = $#ARGV + 1;
my $filename = $ARGV[0];
my $runName = $ARGV[1];
#print "$filename\n";
# terrible hack :(
my $dbh = DBI->connect("dbi:SQLite:dbname=kccProfileDB.sqlite","","");
# if ($shouldClean) { $dbh->do("DROP TABLE IF EXISTS data;");}
$dbh->do("CREATE TABLE if not exists data (
	runName NOT NULL
	, runNum INTEGER NOT NULL
	, ruleName NOT NULL
	, rule NOT NULL
	, locationFile NOT NULL
	, locationFrom NOT NULL
	, locationTo NOT NULL
	, type NOT NULL
	, kind NOT NULL
	, matches BIGINT NOT NULL
	, rewrites BIGINT NOT NULL
	, PRIMARY KEY (runName, runNum, rule)
)");
	# key can't be  locationFile, locationFrom, locationTo, kind because sometimes we don't have that info :(
	# , fragment NULL DEFAULT NULL
	# , initialTries NULL DEFAULT NULL
	# , resolveTries NULL DEFAULT NULL
	# , successes NULL DEFAULT NULL
	# , failures NULL DEFAULT NULL
# $dbh->do("CREATE INDEX if not exists index_runName on data (
	# runName
	# , runNum
# )");
$dbh->do("CREATE INDEX if not exists index_rule on data (
	locationFile
	, locationFrom
	, locationTo
	, kind
)");
# $dbh->do("CREATE INDEX if not exists index_matches on data (
	# matches
# )");

$dbh->do("PRAGMA default_synchronous = OFF");
$dbh->do("PRAGMA synchronous = OFF");
my $runNum = getMaxRunNumFor($runName) + 1;

my $sql = "
	INSERT OR REPLACE INTO 
		data (runName, runNum, ruleName, rule, locationFile, locationFrom, locationTo, type, kind, matches, rewrites) 
		VALUES (
			'$runName'
			, $runNum
			, ?
			, ?
			, ?
			, ?
			, ?
			, ?
			, ?
			, ? - COALESCE((SELECT matches FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT rewrites FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
		)
	";
my $insertOpHandle = $dbh->prepare($sql);
# $sql = "INSERT INTO data (rule, type, kind, matches, rewrites) VALUES (?, ?, ?, ?, ?)";
my $insertEqHandle = $insertOpHandle;

#print "Using $filename as input file\n";
open(MYINPUTFILE, "<$filename");

while(<MYINPUTFILE>) {
	my $line = $_;
	chomp($line);
	if ($line =~ m/^op /){
		handleOp($line, *MYINPUTFILE);
	} elsif ($line =~ m/^(eq|ceq|rl|crl) /){
		handleEq($line, *MYINPUTFILE, $1);
	} else {
		# ignore line
	}
}

$dbh->disconnect;


#############################################
sub handleOp {
	my ($line, $file) = @_;
	my $rule = substr($line, 3);
	my $ruleName = "";
	$line = <$file>;
	if ($line =~ m/built-in eq rewrites: (\d+) \(/){
		my $rewrites = $1;
		my $retval = $insertOpHandle->execute($ruleName, $rule, "", "", "", 'op', 'builtin', $rewrites, $rule, $rewrites, $rule);
		return;
	}
}
sub handleEq {
	my ($line, $file, $type) = @_;
	my $rule = "";
	#$line;
	my $ruleName = "";
	my $kind = 'macro';
	my $locationFile = "";
	my $locationFrom = "";
	my $locationTo = "";
	my $matches = 0;
	my $rewrites = 0;
	my $shouldInsert = 0;
	$_ = "$line\n";
	do {
		$line = $_;
		chomp($line);
		if ($line =~ m/[\[ ]label ([^ ]+)[\] ]/){ $ruleName = $1; }
		if ($line =~ m/filename=\((.*?)\)/) {
			$locationFile = $1;
		}
		if ($line =~ m/location=\((\d+),(\d+),(\d+),(\d+)\)/) {
			$locationFrom = $1;
			$locationTo = $3;
		}
		if ($line =~ m/((?:supercool|superheat|cooling|heating|superheated)=\([^\)]*\))/){
			$kind = $1;
		} elsif ($line =~ m/(structural|computational)/) {
			$kind = $1;
		}
		if ($line =~ m/^rewrites: (\d+) \(/){
			$rewrites = $1;
			$matches = $rewrites;
			$shouldInsert = 1;
			# print "normal\n";
		} elsif ($line =~ m/^lhs matches: (\d+)	rewrites: (\d+) \(/){
			$matches = $1;
			$rewrites = $2;
			$shouldInsert = 1;
			# print "conditional\n";
		}
		if ($shouldInsert) {
			my $retval = $insertEqHandle->execute(
				$ruleName, 
				$rule, 
				$locationFile, 
				$locationFrom, 
				$locationTo, 
				$type, 
				$kind, 
				$matches, $rule, 
				$rewrites, $rule
			);
			return;
		}
		$rule .= "$line\n";
	} while (<$file>);
}

sub getMaxRunNumFor {
	my ($runName) = (@_);
	my $sth = $dbh->prepare("
		SELECT max(runNum) as maxNum
		FROM data a
		WHERE runName like '$runName'
	") or die $dbh->errstr;
	$sth->execute();
	my $hash_ref = $sth->fetchrow_hashref or die "Problem figuring max run for '$runName'";
	return $hash_ref->{maxNum};
} 


