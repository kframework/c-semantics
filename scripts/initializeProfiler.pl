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
	if ($line =~ m/^\s*(?:eq|ceq|rl|crl) .*\[.*metadata.*(heating|cooling|structural|computational).*\]\.\s*$/){
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
# eq __(<_>_</_>((control).CellLabel, __(?16:Bag, <_>_</_>((local).CellLabel, __(?20:Bag, <_>_</_>((localAddresses).CellLabel, ?21:Set, (localAddresses).CellLabel)), (local).CellLabel), <_>_</_>((k).CellLabel, _~>_(_`(_`)(('bindVariadic).KProperLabel, _`,`,_(?17:K, _`(_`)(kList(("wklist_").String), _`,`,_(V:KResult, ?18:List`{KResult`})))), ?19:K), (k).CellLabel)), (control).CellLabel), <_>_</_>((nextLoc).CellLabel, _`(_`)(Rat_(Loc:Nat), (.List`{K`}).List`{KResult`}), (nextLoc).CellLabel)) = __(<_>_</_>((control).CellLabel, __(?16:Bag, <_>_</_>((local).CellLabel, __(?20:Bag, <_>_</_>((localAddresses).CellLabel, __(?21:Set, SetItem(_`(_`)(Rat_(Loc:Nat), (.List`{K`}).List`{KResult`}))), (localAddresses).CellLabel)), (local).CellLabel), <_>_</_>((k).CellLabel, _~>_(_`(_`)(('allocateType).KProperLabel, _`,`,_(_`(_`)(Rat_(Loc:Nat), (.List`{K`}).List`{KResult`}), _`(_`)(('type).KResultLabel, V:KResult))), _`(_`)(('Computation).KProperLabel, _`(_`)(('_:=_).KProperLabel, _`,`,_(_`(_`)(('*_).KProperLabel, _`(_`)(('tv).KResultLabel, _`,`,_(_`(_`)(kList(("wklist_").String), _`(_`)(Rat_(Loc:Nat), (.List`{K`}).List`{KResult`})), _`(_`)(('pointerType).KResultLabel, _`(_`)(('type).KResultLabel, V:KResult))))), V:KResult))), _`(_`)(('bindVariadic).KProperLabel, _`,`,_(?17:K, _`(_`)(kList(("wklist_").String), ?18:List`{KResult`}))), ?19:K), (k).CellLabel)), (control).CellLabel), <_>_</_>((nextLoc).CellLabel, _`(_`)(Rat_(inc(Loc:Nat)), (.List`{K`}).List`{KResult`}), (nextLoc).CellLabel)) [  label bind-variadic  metadata "location(common-c-declarations.k:121-131) structural"   ].




