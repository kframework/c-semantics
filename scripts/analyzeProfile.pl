#!/usr/bin/env perl
use strict;
use DBI;
my $RULE_LENGTH = 20;
my $numArgs = $#ARGV + 1;
my $printFileInfo = 0;
my $shouldPrint = 0;
my $filename = $ARGV[0];
my $runName = $ARGV[1];
#print "$filename\n";
# terrible hack :(
my $dbh = DBI->connect("dbi:SQLite:dbname=maudeProfileDBfile.sqlite","","");
# if ($shouldClean) { $dbh->do("DROP TABLE IF EXISTS data;");}
$dbh->do("CREATE TABLE if not exists data (
	runName NOT NULL
	, runNum INTEGER NOT NULL
	, rule NOT NULL
	, type NOT NULL
	, kind NOT NULL
	, rewrites BIGINT NOT NULL
	, matches BIGINT
	, fragment NULL DEFAULT NULL
	, initialTries NULL DEFAULT NULL
	, resolveTries NULL DEFAULT NULL
	, successes NULL DEFAULT NULL
	, failures NULL DEFAULT NULL
	, PRIMARY KEY (runName, runNum, rule)
)");
$dbh->do("PRAGMA default_synchronous = OFF");
$dbh->do("PRAGMA synchronous = OFF");
my $runNum = getMaxRunNumFor($runName) + 1;


my $sql = "INSERT INTO data (runName, runNum, rule, type, kind, rewrites, matches) VALUES ('$runName', $runNum, ?, ?, ?, ?, ?)";
my $insertOpHandle = $dbh->prepare($sql);
# $sql = "INSERT INTO data (rule, type, kind, rewrites, matches) VALUES (?, ?, ?, ?, ?)";
my $insertEqHandle = $insertOpHandle;
$sql = "INSERT INTO data (runName, runNum, rule, type, kind, rewrites, matches, fragment, initialTries, resolveTries, successes, failures) VALUES ('$runName', $runNum, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";
my $insertCeqHandle = $dbh->prepare($sql);
# $sql = "UPDATE data SET count = count + 1, rewrites = rewrites + ?, matches = matches + ? where rule = ? AND type = ? AND kind = ?";
# my $updateOpHandle = $dbh->prepare($sql);
# # $sql = "UPDATE data SET rewrites = rewrites + ?, matches = matches + ? where rule = ? AND type = ? and kind = ?";
# my $updateEqHandle = $updateOpHandle;
# $sql = "UPDATE data SET count = count + 1, rewrites = rewrites + ?, matches = matches + ?, fragment = fragment + ?, initialTries = initialTries + ?, resolveTries = resolveTries + ?, successes = successes + ?, failures = failures + ? where rule = ? AND type = ?";
# my $updateCeqHandle = $dbh->prepare($sql);
				
#print "Using $filename as input file\n";
open(MYINPUTFILE, "<$filename");
my $line = <MYINPUTFILE>;
# skip header if it's there
if (index($line,"\||||||||||||||||||/") != -1){
	$line = <MYINPUTFILE>; $line = <MYINPUTFILE>;
	$line = <MYINPUTFILE>; $line = <MYINPUTFILE>;
	$line = <MYINPUTFILE>; $line = <MYINPUTFILE>;
}

# after first ==========================================
while(<MYINPUTFILE>) {
	my $line = $_;
	chomp($line);
	if ($line =~ m/^op /){
		handleOp($line, *MYINPUTFILE);
	} elsif ($line =~ m/^eq /){
		handleEq($line, *MYINPUTFILE, 'eq');
	} elsif ($line =~ m/^ceq /){
		handleCeq($line, *MYINPUTFILE, 'ceq');
	} elsif ($line =~ m/^rl /){
		handleEq($line, *MYINPUTFILE, 'rl');
	} elsif ($line =~ m/^crl /){
		handleCeq($line, *MYINPUTFILE, 'crl');
	} else {
		#print "--------------------\n$line\n--------------------\n";
	}
}

$dbh->disconnect;


#############################################
sub handleOp {
	my ($line, $file) = @_;
	my $rule = substr($line, 3);
	$line = <$file>;
	if ($line =~ m/built-in eq rewrites: (\d+) \(/){
		my $rewrites = $1;
		my $retval = $insertOpHandle->execute($rule, 'op', 'builtin', $rewrites, $rewrites);
		# if (!$retval) {
			# $updateOpHandle->execute($rewrites, $rewrites, $rule, 'op', 'builtin');
		# }
		return;
	}
}
sub handleEq {
	my ($line, $file, $type) = @_;
	my $rule = $line;
	my $kind = 'macro';
	while (<$file>){
		$line = $_;
		chomp($line);
		if ($line =~ m/^rewrites: (\d+) \(/){
			my $rewrites = $1;
			my $retval = $insertEqHandle->execute($rule, $type, $kind, $rewrites, $rewrites);
			# if (!$retval) {
				# $updateEqHandle->execute($rewrites, $rewrites, $rule, $type, $kind);
			# }
			return;
		} if ($line =~ m/[\[ ]label ([^ ]+)[\] ]/){ # labeled equation
			$rule = $1;
			# print "$1\n"
		} if ($line =~ m/structural rule/) {
			$kind = 'structural';
		} if ($line =~ m/computational rule/) {
			$kind = 'computational';
		} else {
			$rule .= "$line\n";
		}
	}
}
sub handleCeq {
	my ($line, $file, $type) = @_;
	my $rule = $line;
	my $kind = "macro";
	while (<$file>){
		$line = $_;
		chomp($line);
		if ($line =~ m/^lhs matches: (\d+)	rewrites: (\d+) \(/){
			my $matches = $1;
			my $rewrites = $2;
			$line = <$file>;
			$line = <$file>;
			chomp($line);
			$line =~ m/^(\d+)\t\t(\d+)\t\t(\d+)\t\t(\d+)\t\t(\d+)/;
			my $fragment = $1;
			my $initialTries = $2;
			my $resolveTries = $3;
			my $successes = $4;
			my $failures = $5;
			
			my $retval = $insertCeqHandle->execute($rule, $type, $kind, $rewrites, $matches, $fragment, $initialTries, $resolveTries, $successes, $failures);
			# if (!$retval) {
				# $updateCeqHandle->execute($rewrites, $matches, $fragment, $initialTries, $resolveTries, $successes, $failures, $rule, $type, $kind);
			# }
			return;
		} 
		if ($line =~ m/[\[ ]label ([^ ]+)[\] ]/){ # labeled equation
			$rule = $1;
			# print "$1\n"
		} 
		if ($line =~ m/structural rule/) {
			$kind = 'structural';
		} 
		if ($line =~ m/computational rule/) {
			$kind = 'computational';
		} else {
			$rule .= "$line\n";
		}
	}
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
