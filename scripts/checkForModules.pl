#!/usr/bin/env perl
my @requiredModules = (
	XML::Twig
	, XML::DOM
	, XML::LibXML::Reader
	, Regexp::Common
	, Tree::Nary
	, Text::Diff
	, DBI
	, DBD::SQLite
	, Getopt::Declare
);

my $missingPackage = 0;
foreach my $module (@requiredModules) {
	if (eval "require $module; 1;" ne 1) {
		print "Error: You need to install perl module '$module'\n";
		print "Try running:   cpan -i $module\n";
		$missingPackage = 1;
	}	
}

if ($missingPackage) {
	exit(1);
} else {
	exit(0);
}
