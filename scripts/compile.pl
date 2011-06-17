#!/usr/bin/env perl
use strict;
use File::Spec::Functions qw(rel2abs catfile);
use Getopt::Declare;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
use File::Copy;

my $myDirectory = dirname(rel2abs($0));
#my $slurpScript = catfile($myDirectory, 'slurp.pl');
my $linkScript = catfile($myDirectory, 'link.pl');
#require $slurpScript;
require $linkScript;

my @temporaryFiles = ();
 
# here we trap control-c (and others) so we can clean up when that happens
$SIG{'ABRT'} = 'interruptHandler';
$SIG{'BREAK'} = 'interruptHandler';
$SIG{'TERM'} = 'interruptHandler';
$SIG{'QUIT'} = 'interruptHandler';
$SIG{'SEGV'} = 'interruptHandler';
$SIG{'HUP' } = 'interruptHandler';
$SIG{'TRAP'} = 'interruptHandler';
$SIG{'STOP'} = 'interruptHandler';
$SIG{'INT'} = 'interruptHandler'; # handle control-c 

sub interruptHandler {
	finalCleanup(); # call single cleanup point
	exit(1); # since we were interrupted, we should exit with a non-zero code
}

# this block gets run at the end of a normally terminating program, whether it simply exits, or dies.  We use this to clean up.
END {
	my $retval = $?; # $? contains the value the program would normally have exited with
	finalCleanup(); # call single cleanup point
	exit($retval);
}

# this subroutine can be used as a way to ensure we clean up all resources whenever we exit.  This is going to be mostly temp files.  If the program terminates for almost any reason, this code will be executed.
sub finalCleanup {
	foreach my $file (@temporaryFiles) {
		unlink ($file);
	}
}
 
 
$::VERSION="0.1";
#use vars qw/$not $re/;

my @compiledPrograms = ();
my @shouldBeDeleted = ();

my $stdlib = catfile($myDirectory, 'lib', 'clib.o');

my $warnFlag;
my $dumpFlag;
my $modelFlag;

my $spec = q(#
  -c		Compile and assemble, but do not link
  -i		Include support for runtime file io
  -lm		Ignored
  -n		Allows exploring nondetermism
  -s		Do not link against the standard library
  -o <file>	Place the output into <file>
#-verbose	Do not delete intermediate files
  -w		Do not print warning messages
  <files>...	.c files to be compiled [required]
		{ defer { foreach (@files) { compile($_); } } }
		
There are additional options available at runtime.  Try running your compiled program with HELP set (e.g., HELP=1 ./a.out) to see these
);

 #[mutex: -case -CASE -Case -CaSe]
my @arr = ('-BUILD');
my $args = Getopt::Declare->new($spec,  \@arr);
if (!$args->parse()) {
	#$args->usage(1);
	#exit(0);
	exit(1);
}

if ($args->{'-c'}) {
	exit(0); # compilation was already handled during parsing, so we can exit
}
# otherwise, we're compiling an executable

my $oval = $args->{'-o'} || 'a.out';

my $linkTemp = "mod C-program-linked is including C .\n";

if (! $args->{'-s'}) {
	push(@compiledPrograms, $stdlib);
}
my $linkingResults = linker(@compiledPrograms);
unlink(@shouldBeDeleted);
if ($linkingResults eq ""){
	die "Nothing returned from linker";
}
$linkTemp .= $linkingResults;
$linkTemp .= "endm\n";
# if [ ! "$dumpFlag" ]; then
	# rm -f $compiledPrograms
# fi

#my $baseMaterial = File::Temp->new( TEMPLATE => 'tmp-kcc-base-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK=>0 );
#push(@temporaryFiles, $baseMaterial);

my $semanticsFile;
if ($args->{'-n'}) {
	$semanticsFile = catfile($myDirectory, 'c-total-nd');
} else {
	$semanticsFile = catfile($myDirectory, 'c-total');
}
my @baseMaterialFiles = ($semanticsFile);

open(FILE, catfile($myDirectory, 'programRunner.pl')) or die "Couldn't open file: $!";
my $programRunner = join("", <FILE>);
close(FILE);

my $programTemp = File::Temp->new( TEMPLATE => 'tmp-kcc-prog-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $programTemp);

$programRunner = performSpecializations($programRunner);

print $programTemp "$programRunner\n\n";

# my $slurpingResults = slurp(@baseMaterialFiles);
# if ($slurpingResults eq ""){
	# die "Nothing returned from slurper";
# }

# print $programTemp $slurpingResults;
print $programTemp "sub linkedProgram { return <<'ENDOFCOMPILEDPROGRAM';\n$linkTemp\nENDOFCOMPILEDPROGRAM\n }\n";
# if [ ! "$dumpFlag" ]; then
	# rm -f $linkTemp
# fi

#print "closing $programTemp\n";
close($programTemp);

#rename($programTemp, $oval);
move("$programTemp", $oval) or die "Failed to move the generated program to its destination $oval: $!";
my $numFilesChanged = chmod(0755, $oval);
if ($numFilesChanged != 1) {
	die "Call to chmod $oval failed";
}

exit();
# ===================================================================

sub performSpecializations {
	my ($file) = (@_);
	
	my $ioserver = catfile($myDirectory, 'fileserver.pl');
	my $ioFlag = $args->{'-i'};
	my $mainFileName = $args->{'<files>'}[0];
	my $nondetFlag = $args->{'-n'} ? 1 : 0;
	
	$file =~ s?EXTERN_COMPILED_WITH_IO?$ioFlag?g;
	$file =~ s?EXTERN_IO_SERVER?$ioserver?g;
	$file =~ s?EXTERN_SCRIPTS_DIR?$myDirectory?g;
	$file =~ s?EXTERN_IDENTIFIER?$mainFileName?g;
	$file =~ s?EXTERN_ND_FLAG?$nondetFlag?g;
	return $file;
}


sub compile {
	my ($file) = (@_);
	my $inputFile = rel2abs($file);
	if (! -e $inputFile) {
		die "kcc: $file: No such file or directory";
	}
	my $inputDirectory = dirname($inputFile);
	my ($baseName, $inputDirectory, $suffix) = fileparse($inputFile, '.c');
	open my $fh, $inputFile or die "Could not open $inputFile for reading: $!\n";
	my $line = <$fh>;
	close $fh;
	if ($line =~ /^---kccMarker/) {
		push(@compiledPrograms, $inputFile);
		return;
	}
	# assume it's a normal input file, so compile it
	my $localOval = "$baseName.o";
	my $compileProgramScript = catfile($myDirectory, 'compileProgram.sh');
	system("$compileProgramScript $warnFlag $dumpFlag $modelFlag $inputFile") == 0
		or die "Compilation failed: $?";

	if (! -e "program-$baseName-compiled.maude") {
		die "Expected to find program-$baseName-compiled.maude, but did not";
	}
	move("program-$baseName-compiled.maude", $localOval) or die "Failed to rename the compiled program to the local output file $localOval";
	
	push(@compiledPrograms, $localOval);
	if ($args->{'-c'}) {
		if ($args->{'-o'}) {
			move($localOval, $args->{'-o'}) or die "Failed to move the generated program to its destination $oval: $!";
			#rename($localOval, $args->{'-o'});
		}
	} else {
		push(@shouldBeDeleted, $localOval);
	}
}

__END__
