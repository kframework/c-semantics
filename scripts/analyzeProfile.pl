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
	, ruleName NOT NULL
	, rule NOT NULL
	, locationFile NOT NULL
	, locationFrom NOT NULL
	, locationTo NOT NULL
	, type NOT NULL
	, kind NOT NULL
	, rewrites BIGINT NOT NULL
	, matches BIGINT
	, fragment NULL DEFAULT NULL
	, initialTries NULL DEFAULT NULL
	, resolveTries NULL DEFAULT NULL
	, successes NULL DEFAULT NULL
	, failures NULL DEFAULT NULL
	, PRIMARY KEY (runName, runNum, locationFile, locationFrom, locationTo, kind)
)");
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
		data (runName, runNum, ruleName, rule, locationFile, locationFrom, locationTo, type, kind, rewrites, matches) 
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
			, ? - COALESCE((SELECT rewrites FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT matches FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
		)
	";
my $insertOpHandle = $dbh->prepare($sql);
# $sql = "INSERT INTO data (rule, type, kind, rewrites, matches) VALUES (?, ?, ?, ?, ?)";
my $insertEqHandle = $insertOpHandle;
$sql = "
	INSERT INTO 
		data (runName, runNum, ruleName, rule, locationFile, locationFrom, locationTo, type, kind, rewrites, matches, fragment, initialTries, resolveTries, successes, failures) 
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
			, ? - COALESCE((SELECT rewrites FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT matches FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT fragment FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT initialTries FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT resolveTries FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT successes FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
			, ? - COALESCE((SELECT failures FROM data WHERE runName == 'tmpSemanticCalibration' AND runNum == 1 AND rule = ?), 0)
		)
	";
my $insertCeqHandle = $dbh->prepare($sql);
				
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
		# < files > ?16:Map </ files > [label terminate metadata "computational location(dynamic-c-semantics.k:100-109)"] .
# rewrites: 1 (0.00067079%)

		#print "--------------------\n$line\n--------------------\n";
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
		# if (!$retval) {
			# $updateOpHandle->execute($rewrites, $rewrites, $rule, 'op', 'builtin');
		# }
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
	$_ = "$line\n";
	do {
		$line = $_;
		chomp($line);
		$rule .= "$line\n";
		if ($line =~ m/[\[ ]label ([^ ]+)[\] ]/){ # labeled equation
			$ruleName = $1;
		}
		if ($line =~ m/location\(([^:]+):(\d+)-(\d+)\)/) {
			$locationFile = $1;
			$locationFrom = $2;
			$locationTo = $3;
		}
		if ($line =~ m/location\(([^:]+):(\d+)\)/) {
			$locationFile = $1;
			$locationFrom = $2;
			$locationTo = $2;
		}
		if ($line =~ m/structural/) {
			$kind = 'structural';
		} elsif ($line =~ m/computational/) {
			$kind = 'computational';
		} elsif ($line =~ m/cooling/) {
			$kind = 'cooling';
		} elsif ($line =~ m/heating/) {
			$kind = 'heating';
		}
		if ($line =~ m/^rewrites: (\d+) \(/){
			my $rewrites = $1;
			my $retval = $insertEqHandle->execute($ruleName, $rule, $locationFile, $locationFrom, $locationTo, $type, $kind, $rewrites, $rule, $rewrites, $rule);
			# if (!$retval) {
				# $updateEqHandle->execute($rewrites, $rewrites, $rule, $type, $kind);
			# }
			return;
		} 
	} while (<$file>);
}
sub handleCeq {
	my ($line, $file, $type) = @_;
	my $rule = "";
	my $kind = "macro";
	my $locationFile = "";
	my $locationFrom = "";
	my $locationTo = "";
	my $ruleName = "";
	$_ = "$line\n";
	do {
		$line = $_;		
		chomp($line);
		$rule .= "$line\n";
		
		if ($line =~ m/[\[ ]label ([^ ]+)[\] ]/){ # labeled equation
			$ruleName = $1;
		} 
		#roperLabel(Kcxt:KResult)) ~> Rest:K </ k > [metadata "cooling location(common-c-memory.k:70)"] .
		if ($line =~ m/location\(([^:]+):(\d+)-(\d+)\)/) {
			$locationFile = $1;
			$locationFrom = $2;
			$locationTo = $3;
		}
		if ($line =~ m/location\(([^:]+):(\d+)\)/) {
			$locationFile = $1;
			$locationFrom = $2;
			$locationTo = $2;
		}
		if ($line =~ m/structural/) {
			$kind = 'structural';
		} elsif ($line =~ m/computational/) {
			$kind = 'computational';
		} elsif ($line =~ m/cooling/) {
			$kind = 'cooling';
		} elsif ($line =~ m/heating/) {
			$kind = 'heating';
		}
		
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
			
			my $retval = $insertCeqHandle->execute($ruleName, $rule, $locationFile, $locationFrom, $locationTo, $type, $kind, $rewrites, $rule, $matches, $rule, $fragment, $rule, $initialTries, $rule, $resolveTries, $rule, $successes, $rule, $failures, $rule);
			return;
		}
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


