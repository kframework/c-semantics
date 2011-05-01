#!/usr/bin/env perl
use strict;
use File::Spec::Functions qw(rel2abs catfile);
use Getopt::Declare;
use File::Basename;
use File::Temp qw/ tempfile tempdir /;
#require 'link.pl';

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
	# my ($val) = (@_);
	# print "$val\n";
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
	print "In final cleanup\n";
	foreach my $file (@temporaryFiles) {
		print "unlinking $file\n";
		unlink ($file);
	}
	# clean(); # delete normal kompile files
	#	clean() if !$verbose;
	#unlink($maude_xml_file); # we don't want to put this in clean, since clean gets called before the xml file is used
}
 
 
$::VERSION="0.1";
#use vars qw/$not $re/;
my $flagCompileOnly;
my $myDirectory = dirname(rel2abs($0));
my @compiledPrograms = ();

my $stdlib = catfile($myDirectory, 'lib', 'clib.o');

my $warnFlag;
my $dumpFlag;
my $modelFlag;

my $spec = q(#
-c		Compile and assemble, but do not link
		{ $::flagCompileOnly = '-c' }
-i		Include support for runtime file io
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

my $args = Getopt::Declare->new($spec);

if ($args->{'-c'}) {
	exit(0); # compilation was already handled during parsing, so we can exit
}

my $oval = $args->{'-o'} || 'a.out';

my $linkTemp = File::Temp->new( TEMPLATE => 'tmp-kcc-link-XXXXXXXXXXX', SUFFIX => '.maude' );
push(@temporaryFiles, $linkTemp);

print $linkTemp 'mod C-program-linked is including C .\n';

my $linker = catfile($myDirectory, 'link.pl');
if ($args->{'-s'}) {
	system("perl $linker @compiledPrograms >> $linkTemp") == 0
		or die "Compilation failed: $?";
} else {
	system("perl $linker @compiledPrograms $stdlib >> $linkTemp") == 0
		or die "Compilation failed: $?";
}
print $linkTemp "endm\n";

# if [ ! "$dumpFlag" ]; then
	# rm -f $compiledPrograms
# fi

my $baseMaterial = File::Temp->new( TEMPLATE => 'tmp-kcc-base-XXXXXXXXXXX', SUFFIX => '.maude' );
push(@temporaryFiles, $baseMaterial);

my $semanticsFile;
if ($args->{'-n'}) {
	$semanticsFile = catfile($myDirectory, 'c-total-nd');
} else {
	$semanticsFile = catfile($myDirectory, 'c-total');
}
print $baseMaterial "load $semanticsFile\n";
print $baseMaterial "load $linkTemp\n";

# # no more polyglot :(  now we use a script that copies all the maude to its own file
# cat $myDirectory/programRunner.sh \
	# | sed "s?EXTERN_WRAPPER?$myDirectory/wrapper.pl?g" \
	# | sed "s?EXTERN_SEARCH_GRAPH_WRAPPER?$myDirectory/graphSearch.pl?g" \
	# | sed "s?EXTERN_COMPILED_WITH_IO?$ioFlag?g" \
	# | sed "s?EXTERN_IO_SERVER?$myDirectory/fileserver.pl?g" \
	# | sed "s?EXTERN_SCRIPTS_DIR?$myDirectory?g" \
	# | sed "s?EXTERN_IDENTIFIER?$mainFileName?g" \
	# | sed "s?EXTERN_ND_FLAG?$nondetFlag?g" \
	# > $programTemp
# echo >> $programTemp
# cat $baseMaterial | perl $myDirectory/slurp.pl >> $programTemp
# if [ ! "$dumpFlag" ]; then
	# rm -f $linkTemp
# fi
# chmod u+x $programTemp
# mv $programTemp $oval


sub compile {
	my ($file) = (@_);
	my $inputFile = rel2abs($file);
	if (! -e $inputFile) {
		die "kcc: $file: No such file or directory";
	}
	my $inputDirectory = dirname($inputFile);
	my ($baseName, $inputDirectory, $suffix) = fileparse($inputFile, '.c');
	my $localOval = "$baseName.o";
	
	my $compileProgramScript = catfile($myDirectory, 'compileProgram.sh');
	
	system("$compileProgramScript $warnFlag $dumpFlag $modelFlag $inputFile") == 0
		or die "Compilation failed: $?";

	if (! -e "program-$baseName-compiled.maude") {
		die "Expected to find program-$baseName-compiled.maude, but did not";
	}
	rename("program-$baseName-compiled.maude", $localOval);
	push(@compiledPrograms, $localOval);
	if ($flagCompileOnly) {
		if ($args->{'-o'}) {
			rename($localOval, $args->{'-o'});
		}
	}	
}

__END__
