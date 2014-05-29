#!/usr/bin/env perl
use strict;
my @requiredModules = qw(
	XML::LibXML::Reader
	Text::Diff
	DBI
	DBD::SQLite
	Getopt::Declare
      MIME::Base64
      IO::Compress::Gzip
      IO::Uncompress::Gunzip
);
my @missingPackages = ();

my $missingPackage = checkPackages();
if (!$missingPackage) {
	exit(0);
}

# At this point, we're missing at least one package.
print "ERROR: You are missing some required perl modules.  It's probably best to install them using the package manager for your operating system.\n\nWould you like me to try installing these packages automatically by running `cpan -i @missingPackages`? (Y/N)";
my $response = <STDIN>;
chomp($response);
if (uc($response) eq 'Y') {
	tryInstalling();
} elsif (uc($response) eq 'N') {
	print "You may try installing them yourself by running something like:\n";
	print "cpan -i @missingPackages\n";
	exit(1);
} else {
	print "ERROR: I didn't understand what you said.  Exiting...\n";
	exit(1);
}

sub tryInstalling {
	print "Okay, I'm going to try installing the packages by running `cpan -i @missingPackages`\n";
	system("PERL_MM_USE_DEFAULT=1 cpan -i @missingPackages");
	my $missingPackage = checkPackages();
	if (!$missingPackage) {
		print "The missing packages were installed successfully.\n";
		exit(0);
	} else {
		print "ERROR: You're still missing some packages.  You can either rerun 'make' to try again, or install them yourself.  Sometimes `cpan` must be run with sudo privileges.\n";
		exit(1);
	}
}

sub checkPackages {
	my $missingPackage = 0;
	@missingPackages = ();
	foreach my $module (@requiredModules) {
		if (eval "require $module; 1;" ne 1) {
			print "ERROR: You need to install perl module '$module'\n";
			#print "Try running:   cpan -i $module\n";
			push(@missingPackages, $module);
			$missingPackage = 1;
		}
	}
	return $missingPackage;
}


