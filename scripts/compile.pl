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

my @stdlib = ();
push(@stdlib, catfile($myDirectory, 'lib', 'clib.o'));
push(@stdlib, catfile($myDirectory, 'lib', 'ctype.o'));
push(@stdlib, catfile($myDirectory, 'lib', 'math.o'));
push(@stdlib, catfile($myDirectory, 'lib', 'stdio.o'));
push(@stdlib, catfile($myDirectory, 'lib', 'stdlib.o'));
push(@stdlib, catfile($myDirectory, 'lib', 'string.o'));
my $xmlToK = catfile($myDirectory, 'xmlToK.pl');
my $cparser = catfile($myDirectory, 'cparser');

my @gccDefines = ();
my @gccIncludeDirs = ();

my $spec = q(#
  -c				Compile and assemble, but do not link
#-i				Include support for runtime file io
  -d				Keep intermediate files
  -D <name>[=<definition>]	Predefine <name> as a macro, with definition <definition>.
					{ push(@::gccDefines, " -D$name=\"" . ((defined $definition) ? "$definition" : "1") . "\" "); }
  -I <dir>			Look for headers in <dir>
					{ push(@::gccIncludeDirs, " -I$dir "); }
  -s				Do not link against the standard library
  -o <file>			Place the output into <file>
  -p				Profile parsing
#-verbose			Do not delete intermediate files
  -w				Do not print warning messages
  <files>...			.c files to be compiled [required]
		{ defer { foreach (@files) { compile($_); } } }
#-funsigned-char		Let the type "char" be unsigned, like "unsigned char"
#-fsigned-char			Let the type "char" be signed, like "signed char"
#-fbits-per-byte <num>		Sets the number of bits in a byte
#[mutex: -funsigned-char -fsigned-char]
  -lm				Ignored
  -O[<level:/0|1|2|3|s/>]	Ignored
  -std <standard>		Ignored
  -x <language>			Ignored
  -pedantic			Ignored
  -Wall				Ignored
		
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
$linkTemp .= "including #MODEL-CHECK .\n";

if (! $args->{'-s'}) {
	push(@compiledPrograms, @stdlib);
}
my $linkingResults = linker(@compiledPrograms);
unlink(@shouldBeDeleted);
if ($linkingResults eq ""){
	die "Nothing returned from linker";
}
$linkTemp .= $linkingResults;
$linkTemp .= "endm\n";

open(FILE, catfile($myDirectory, 'programRunner.pl')) or die "Couldn't open file: $!";
my $programRunner = join("", <FILE>);
close(FILE);

my $programTemp = File::Temp->new( TEMPLATE => 'tmp-kcc-prog-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
push(@temporaryFiles, $programTemp);

$programRunner = performSpecializations($programRunner);

print $programTemp "$programRunner\n\n";

print $programTemp "sub linkedProgram { return <<'ENDOFCOMPILEDPROGRAM';\n$linkTemp\nENDOFCOMPILEDPROGRAM\n }\n";

close($programTemp);

move("$programTemp", $oval) or die "Failed to move the generated program to its destination $oval: $!";
my $numFilesChanged = chmod(0755, $oval);
if ($numFilesChanged != 1) {
	die "Call to chmod $oval failed";
}

exit();
# ===================================================================

sub performSpecializations {
	my ($file) = (@_);
	
	my $ioserver = catfile($myDirectory, 'wrapperAndServer.jar');
	# my $cmdlineParse = catfile($myDirectory, 'jopt-simple-3.3.jar');
	
	my $wrapperCommand = "java -jar $ioserver";
	#my $ioFlag = $args->{'-i'};
	my $mainFileName = $args->{'<files>'}[0];
	my $nondetFlag = $args->{'-n'} ? 1 : 0;
	
	#$file =~ s?EXTERN_COMPILED_WITH_IO?$ioFlag?g;
	$file =~ s?EXTERN_IO_SERVER?$wrapperCommand?g;
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
	my ($baseName, $inputDirectory, $suffix) = fileparse($inputFile, ('\.c', '\.o', '\.a'));
	#print "basename = $baseName\n";
	#print "inputDirectory = $inputDirectory\n";
	#print "suffix = $suffix\n";
	if (($suffix eq '.o') or ($suffix eq '.a')) {
		# assuming .o or .a file
		push(@compiledPrograms, $inputFile);
		return;
	}
	open my $fh, $inputFile or die "Could not open $inputFile for reading: $!\n";
	my $line = <$fh>;
	close $fh;
	# # if the file was already compiled, return
	# if ($line =~ /^---kccMarker/) {
		# push(@compiledPrograms, $inputFile);
		# return;
	# }
	# assume it's a normal input file, so compile it
	my $localOval = "$baseName.o";
	my $compileProgramScript = catfile($myDirectory, 'compileProgram.sh');
	compileProgram($args->{'-w'}, $args->{'-d'}, $inputFile) or die "Compilation failed";
	# system("$compileProgramScript $warnFlag $dumpFlag $modelFlag $inputFile") == 0
		# or die "Compilation failed: $?";

	if (! -e "program-$baseName-compiled.maude") {
		die "Expected to find program-$baseName-compiled.maude, but did not";
	}
	move("program-$baseName-compiled.maude", $localOval) or die "Failed to rename the compiled program to the local output file $localOval";
	
	push(@compiledPrograms, $localOval);
	if ($args->{'-c'}) {
		if ($args->{'-o'}) {
			move($localOval, $args->{'-o'}) or die "Failed to move the generated program to its destination $oval: $!";
		}
	} else {
		push(@shouldBeDeleted, $localOval);
	}
}


sub compileProgram {
	my ($warnFlag, $dumpFlag, $inputFile) = (@_);
	my $nowarn = $warnFlag;
	my $dflag = $dumpFlag;
	
	# print "dflag=$dflag\n";
	# print "nowarn=$nowarn\n";

	my $PEDANTRY_OPTIONS = "-Wall -Wextra -Werror -Wmissing-prototypes -pedantic -x c -std=c99";
	my $GCC_OPTIONS = "-CC -std=c99 -nostdlib -nodefaultlibs -U __GNUC__";
	
	my $K_PROGRAM_COMPILE;
	if ($args->{'-p'}) {
		$K_PROGRAM_COMPILE = "perl -d:DProf $xmlToK";
	} else {
		$K_PROGRAM_COMPILE = "perl $xmlToK";
	}
	
	my $compilationLog = File::Temp->new( TEMPLATE => 'tmp-kcc-comp-log-XXXXXXXXXXX', SUFFIX => '.maude', UNLINK => 0 );
	push(@temporaryFiles, $compilationLog);
	
	my $trueFilename = $inputFile;
	my ($filename, $directoryname, $suffix) = fileparse($inputFile, '.c');
	my $fullfilename = catfile($directoryname, "$filename.c");
	if (! -e $fullfilename) {
		die "$filename.c not found";
	}
	
	# print "@::gccDefines\n";
	my $gccCommand = "gcc $PEDANTRY_OPTIONS $GCC_OPTIONS @::gccDefines @::gccIncludeDirs -E -iquote . -iquote $directoryname -I $myDirectory/includes $fullfilename 1> $filename.pre.gen 2> $filename.warnings.log";
	# print "$gccCommand\n";
	my $retval = system($gccCommand);
	open FILE, "$filename.warnings.log";
	my @lines = <FILE>;
	close FILE;
	if ($retval) {
		print STDERR "Error running preprocessor:\n";
		print STDERR join("\n", @lines);
		die();
	}
	if (! $nowarn) {
		print join("\n", @lines);
	}
	$retval = system("$cparser $filename.pre.gen --trueName $trueFilename 2> $filename.warnings.log 1> $filename.gen.parse.tmp");
	open FILE, "$filename.warnings.log";
	@lines = <FILE>;
	close FILE;
	if ($retval) {
		unlink("$filename.gen.parse.tmp");
		unlink("$filename.warnings.log");
		print STDERR "Error running C parser:\n";
		print STDERR join("\n", @lines);
		die();		
	}
	if (! $nowarn) {
		print join("\n", @lines);
	}
	if (! $dflag) {
		unlink("$filename.pre.gen");
		unlink("$filename.warnings.log");
	}
	move("$filename.gen.parse.tmp", "$filename.gen.parse") or die "Failed to move $filename.gen.parse.tmp to $filename.gen.parse: $!";
	
	my $PROGRAMRET = system("cat $filename.gen.parse | $K_PROGRAM_COMPILE 2> $compilationLog 1> program-$filename-compiled.maude");
	open FILE, "$compilationLog" or die "Could not open $compilationLog";
	@lines = <FILE>;
	close FILE;
	if (! $dflag) {
		unlink("$filename.gen.parse");
	}
	if ($PROGRAMRET) {
		print STDERR "Error compiling program:\n";
		print STDERR join("\n", @lines);
		unlink($compilationLog);
		die();
	}
	if ($args->{'-p'}) {
		print `dprofpp`;
	}
	return 1;
}

__END__
