use strict;
use DBI;

my $filename = $ARGV[0];
my $RULE_LENGTH = 20;
my $dbh = DBI->connect("dbi:SQLite:dbname=maudeProfileDBfile.sqlite","","");
$dbh->do("CREATE TABLE if not exists rules (	
	ruleName NOT NULL
	, locationFile NOT NULL
	, locationFrom NOT NULL
	, locationTo NOT NULL
	, isLibrary BOOLEAN NOT NULL
	, type NOT NULL
	, kind NOT NULL
	, PRIMARY KEY (locationFile, locationFrom, locationTo, kind)
)");
$dbh->do("PRAGMA default_synchronous = OFF");
$dbh->do("PRAGMA synchronous = OFF");
my $sql = "
	INSERT INTO 
		rules (ruleName, locationFile, locationFrom, locationTo, isLibrary, type, kind) 
		VALUES (?, ?, ?, ?, ?, ?, ?)
	";
my $insertHandle = $dbh->prepare($sql);

open(MYINPUTFILE, "<$filename");
my $line = <MYINPUTFILE>;

while(<MYINPUTFILE>) {
	my $line = $_;
	chomp($line);
	my $ruleName = "";
	my $locationFile = "";
	my $locationFrom = "";
	my $locationTo = "";
	my $isLibrary = 0;
	my $type = "";
	my $kind = "";
	if ($line =~ m/^\s*(eq|ceq|rl|crl) .*\[.*\]\.\s*$/){
		$type = $1;
		#print "Found rule\n";
	}
	if ($line =~ m/^\s*(?:eq|ceq|rl|crl) .*\[.* label ([^ ]*) .*\]\.\s*$/){
		$ruleName = $1;
	}
	if ($line =~ m/^\s*(?:eq|ceq|rl|crl) .*\[.*metadata.*location\(([^:]+):(\d+)-(\d+)\).*\]\.\s*$/){
		$locationFile = $1;
		$locationFrom = $2;
		$locationTo = $3;
		if ($locationFile eq "common-c-standard-lib.k") {
			$isLibrary = 1;
		}
	} elsif ($line =~ m/^\s*(?:eq|ceq|rl|crl) .*\[.*metadata.*location\(([^:]+):(\d+)\).*\]\.\s*$/){
		$locationFile = $1;
		$locationFrom = $2;
		$locationTo = $2;
		if ($locationFile eq "common-c-standard-lib.k") {
			$isLibrary = 1;
		}
	}
	if ($line =~ m/^\s*(?:eq|ceq|rl|crl) .*\[.*metadata.*(super cooling).*\]\.\s*$/){
		$kind = $1;
	} elsif ($line =~ m/^\s*(?:eq|ceq|rl|crl) .*\[.*metadata.*(heating|cooling|structural|computational).*\]\.\s*$/){
		$kind = $1;
	} else {
		$kind = 'macro';
	}
	if ($locationFile && $locationFrom && $locationTo) { 
		my $retval = $insertHandle->execute($ruleName, $locationFile, $locationFrom, $locationTo, $isLibrary, $type, $kind);
		if ($retval != 1){
			print "$locationFile, $locationFrom, $locationTo\n";
		}
		
	}
}
