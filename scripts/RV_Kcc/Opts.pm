package RV_Kcc::Opts;

use v5.10;
use strict;
use warnings;

use Exporter;
use Fcntl qw(SEEK_END);
use File::Basename qw(basename fileparse);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use Getopt::Declare;

use RV_Kcc::Shell qw(shell);
use RV_Kcc::Files qw(distDir tempFile tempDir nativeCC error);

use constant MAGIC        => "\x7fKAST";
use constant RVMAIN       => '__rvmatch_main'; # Symbol 'main' gets rewritten to in natively-compiled code.
use constant BASE_LIBS    => ('-lmpfr', '-lgmp', '-lffi', '-lm', '-ldl');

our $VERSION = 1.00;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
      getopts
      arg
      classify
      cppArgs
      suppressions
      ifdefs
      ldArgs
      nativeObjFiles
      srcFiles
      objFiles
      trampolineFiles
      breakpoints
      RVMAIN
      BASE_LIBS
      MAGIC
);

my $pseudoArgs = {};

sub cppArgs { (@{$pseudoArgs->{cppArgs} || []}); }
sub suppressions { (@{$pseudoArgs->{suppressions} || []}); }
sub ifdefs { (@{$pseudoArgs->{ifdefs} || []}); }
sub ldArgs { (@{$pseudoArgs->{ldArgs} || []}); }
sub nativeObjFiles { (@{$pseudoArgs->{nativeObjFiles} || []}); }
sub srcFiles { (@{$pseudoArgs->{srcFiles} || []}); }
sub objFiles { (@{$pseudoArgs->{objFiles} || []}); }
sub trampolineFiles { (@{$pseudoArgs->{trampolineFiles} || []}); }
sub breakpoints { (@{$pseudoArgs->{breakpoints} || []}); }

my $hasStdin = 0;
my $args;

our $xLang = 'none';
our @incompleteBreakpoints = ();

our %cppWarns = map {$_ => 1} (
      "import",
      "char-subscripts",
      "comment",
      "format",
      "format-y3k",
      "format-extra-args",
      "format-zero-length",
      "format-nonliteral",
      "format-security",
      "format=3",
      "nonnull",
      "init-self",
      "implicit-int",
      "implicit-function-declaration",
      "error-implicit-function-declaration",
      "implicit",
      "main",
      "missing-braces",
      "parentheses",
      "sequence-point",
      "return-type",
      "switch",
      "switch-default",
      "switch-enum",
      "trigraphs",
      "unused-function",
      "unused-label",
      "unused-parameter",
      "unused-variable",
      "unused-value",
      "unused",
      "uninitialized",
      "unknown-pragmas",
      "strict-aliasing",
      "all",
      "extra",
      "div-by-zero",
      "system-headers",
      "float-equal",
      "traditional",
      "declaration-after-statement",
      "undef",
      "endif-labels",
      "shadow",
      "larger-than-len",
      "pointer-arith",
      "bad-function-cast",
      "cast-qual",
      "cast-align",
      "write-strings",
      "conversion",
      "sign-compare",
      "aggregate-return",
      "strict-prototypes",
      "old-style-definition",
      "missing-prototypes",
      "missing-declarations",
      "missing-noreturn",
      "missing-format-attribute",
      "multichar",
      "deprecated-declarations",
      "packed",
      "padded",
      "redundant-decls",
      "nested-externs",
      "unreachable-code",
      "inline",
      "invalid-pch",
      "long-long",
      "disabled-optimization",
      "error"
);

sub arg {
      my ($a) = @_;
      return $args->{$a};
}

sub isKObj {
      my ($filename) = @_;
      open(my $file, $filename) or return 0;
      my $buf;
      seek($file, -5, SEEK_END);
      read($file, $buf, 5);
      close($file);
      return $buf eq MAGIC;
}

sub getIgnoredFlags {
      my $ignoredFlagsRegex = "^(";
      my $sep = "";
      open my $fh, '<', distDir('ignored-flags')
            or error("Couldn't load ignored flag list. Please touch " . distDir('ignored-flags') . ".\n");
      while (<$fh>) {
            chop($_);
            $ignoredFlagsRegex = "$ignoredFlagsRegex$sep(?:$_)";
            $sep = "|";
      }
      $ignoredFlagsRegex = "$ignoredFlagsRegex)\$";
      qr/$ignoredFlagsRegex/;
};

sub isAr {
      my ($filename) = @_;
      return (shell("ar t $filename")->result() == 0);
}

sub isNativeObj {
      my ($file) = @_;
      return (shell("nm $file")->result() == 0);
}

sub classify {
      my ($file, $lang) = @_;

      if ($lang eq 'none') {
            if ($file eq '-') {
                  $hasStdin = 1;
                  $lang = 'c';
            } else {
                  my ($base, $dir, $suffix) = fileparse($file,
                        ('\.c', '\.cc', '\.cp', '\.cxx', '\.cpp', '\.CPP', '\.c++',
                              '\.C', '\.h', '\.hh', '\.hp', '\.hxx', '\.hpp', '\.HPP',
                              '\.h++', '\.H', '\.tcc', '\.s', '\.S', '\.sx'));
                  if ($suffix eq '.c' or $suffix eq '.h') {
                        $lang = 'c';
                  } elsif ($suffix eq '.s') {
                        $lang = 'assembler';
                  } elsif ($suffix eq '.S' or $suffix eq '.sx') {
                        $lang = 'assembler-with-cpp';
                  } elsif ($suffix ne '') {
                        $lang = 'c++';
                  }
            }
      }

      if ($lang eq 'assembler' or $lang eq 'assembler-with-cpp') {
            pushArg('srcFiles', $file, $lang);
      } elsif ($lang eq 'c' or $lang eq 'c-header') {
            pushArg('srcFiles', $file, 'c');
      } elsif ($lang eq 'c++' or $lang eq 'c++-header') {
            pushArg('srcFiles', $file, 'c++');
      } elsif ($lang ne 'none') {
            error("Unsupported -x option: $lang\n");
      } elsif (isAr($file)) {
            extractStatic($file);
      } elsif (isKObj($file)) {
            extractKObj($file);
      } elsif (isNativeObj($file) or -e $file) {
            pushArg('nativeObjFiles', $file);
            pushArg('ldArgs', $file);
      } else {
            if (!($file =~ getIgnoredFlags())) {
                  warn("Unsupported option: $file\n");
            }
      }
}

sub extractKObj {
      my ($file) = @_;
      my $basename = basename($file);
      my $kast = tempFile("$basename-kast");
      my $obj = tempFile("$basename-obj");
      my $trampolines = tempFile("$basename-trampolines");
      shell(distDir('split-kcc-obj'), $file, $obj, $kast, $trampolines)->run();
      pushArg('objFiles', $kast);
      pushArg('nativeObjFiles', $obj);
      pushArg('ldArgs', $obj);
      pushArg('trampolineFiles', $trampolines);
}

sub extractStatic {
      my ($file) = @_;
      my ($basename, undef, $suffix) = fileparse($file);
      -e $file or error("$file does not exist.\n");
      my $tempDir = tempDir('ar');
      copy ($file, $tempDir);
      shell("cd $tempDir && ar -x $basename$suffix")->run();
      opendir my $dir, $tempDir or error("Cannot open directory: $tempDir\n");
      my @files = readdir $dir;
      closedir $dir;
      my @repackageObjs = ();
      for (@files) {
            if ($_ ne "$basename$suffix" && $_ ne "." && $_ ne "..") {
                  if (isKObj(catfile($tempDir, $_))) {
                        my $kast = tempFile("ar-kast-$_");
                        my $obj = tempFile("ar-obj-$_");
                        my $trampolines = tempFile("ar-trampolines-$_");
                        shell(distDir('split-kcc-obj'), catfile($tempDir, $_), $obj, $kast, $trampolines)->run();
                        pushArg('objFiles', $kast);
                        pushArg('trampolineFiles', $trampolines);
                        push(@repackageObjs, $obj);
                  } else {
                        push(@repackageObjs, catfile($tempDir, $_));
                  }
            }
      }
      if (scalar @repackageObjs) {
            my $repackaged = tempFile('repackaged', "-$basename");
            shell("ar rcs $repackaged @repackageObjs")->run();
            pushArg('ldArgs', $repackaged);
      }
}


sub classifyLib {
      my ($lib) = @_;
      for (@{$pseudoArgs->{ldLibs}}) {
            my $candidate = catfile($_, "lib$lib.so");
            if (-e $candidate) {
                  classify($candidate, 'none');
                  return;
            }
            $candidate = catfile($_, "lib$lib.a");
            if (-e $candidate) {
                  classify($candidate, 'none');
                  return;
            }
      }
      pushArg('ldArgs', "-l$lib");
}

sub pushArg {
      my ($arg, @vals) = @_;
      if (!defined $pseudoArgs->{$arg}) {
            $pseudoArgs->{$arg} = [@vals];
      } else {
            push @{$pseudoArgs->{$arg}}, @vals;
      }
}

sub getopts {
      pushArg('ldArgs', BASE_LIBS, '-Wl,--unresolved-symbols=ignore-all', '-Wl,--no-as-needed', '-u', RVMAIN);
      if ((split /\./, shell(nativeCC(), '-dumpversion')->stdout()->run())[0] + 0 >= 5) { # gcc version >= 5
            pushArg('ldArgs', '-no-pie');
      }

      if (!parseOpts()) {
            return 0;
      }

      if (!arg('-no-pedantic')) {
            pushArg('cppArgs', '-pedantic');
      }

      if ($hasStdin && !arg('-E') && !arg('-x')) {
            error("-E or -x required when input is from standard input.\n");
      }

      return 1;
}

sub parseOpts {
      my $self = ({});
      sub usage {}
      bless $self;
      my $_args = join(' ', @ARGV);
      my $_get_nextline = sub { undef };

      $args = $self;

      $args->{_internal}{source} = '';
      $args->{_internal}{args} = (());
      $args->{_internal}{args}[0]{required} = 1;
      $args->{_internal}{args}[0]{desc} = "<files>...";

=for Getopt::Declare
  [strict]
  -version		Show version information. [undocumented]
      {
            print("\n	" . RV_Kcc::Shell::commandName() . ": version 1.0 GNU-compatible\n\n");

            my $buildNumber = do {
                  local $/ = undef;
                  if (open my $fh, '<', RV_Kcc::Files::distDir('build-number')) {
                        <$fh>;
                  } else { ''; }
            };

            if ($buildNumber ne '') {
                  print("	Build number: $buildNumber\n");
            }
            my $profile = RV_Kcc::Files::currentProfile();
            my $defaultProfile = RV_Kcc::Files::defaultProfile();

            my $profiles = join("\n	                    ", RV_Kcc::Files::getProfiles());
            print("	Current profile: $profile\n	Installed profiles: $profiles\n	Default profile: $defaultProfile\n\n	To request additional profiles, contact runtimeverification.com/support.\n\n");
            exit 0;
      }
  -Version		[ditto] [undocumented]
  -VERSION		[ditto] [undocumented]
  --version		[ditto] [undocumented]
  --Version		[ditto] [undocumented]
  --VERSION		[ditto] [undocumented]
  -v			[ditto] [undocumented]
  -V			[ditto] [undocumented]
  -help			Show this message. [undocumented]
      {
            print Getopt::Declare::usage_string($self);
            exit 0;
      }
  -Help			[ditto] [undocumented]
  -HELP			[ditto] [undocumented]
  --help		[ditto] [undocumented]
  --Help		[ditto] [undocumented]
  --HELP		[ditto] [undocumented]
  -h			[ditto] [undocumented]
  -H			[ditto] [undocumented]
  -c			Compile and assemble, but do not link.
  -shared		Compile and assemble into a single object file.
  -d			Print debugging information.
      { RV_Kcc::Shell::enableDebugging(); }
  -D <name>[=[<definition>]]	Predefine <name> as a macro, with definition
				<definition>.
      {
            if (defined $definition) {
                  RV_Kcc::Opts::pushArg('cppArgs', "-D$name=$definition");
            } elsif ($_PUNCT_{"="}) {
                  RV_Kcc::Opts::pushArg('cppArgs', "-D$name=");
            } else  {
                  RV_Kcc::Opts::pushArg('cppArgs', "-D$name");
            }
      }
  -U <name>		Undefine <name> as a macro.
      { RV_Kcc::Opts::pushArg('cppArgs', "-U$name"); }
  -P			Inhibit preprocessor line numbers.
      { RV_Kcc::Opts::pushArg('cppArgs', "-P"); }
  -e <symbol>	Use <symbol> as the program entry point instead of main.
  -E			Preprocess only.
  -I <dir>		Look for headers in <dir>.
      { RV_Kcc::Opts::pushArg('cppArgs', '-I', $dir); }
  -idirafter <dir>	Look for headers in <dir>, but only after directories
			specified with -I and system directories.
      { RV_Kcc::Opts::pushArg('cppArgs', '-idirafter', $dir); }
  -iquote <dir>		Look for headers with quotation marks in <dir>.
      { RV_Kcc::Opts::pushArg('cppArgs', '-iquote', $dir); }
  -isystem <dir>	Look for system headers in <dir>.
      { RV_Kcc::Opts::pushArg('cppArgs', '-isystem', $dir); }
  -include <file>	Add header to file during preprocessing.
      { RV_Kcc::Opts::pushArg('cppArgs', '-include', $file); }
  -L <dir>		Look for shared libraries in <dir>.
      {
            RV_Kcc::Opts::pushArg('ldLibs', $dir);
            RV_Kcc::Opts::pushArg('ldArgs', "-L$dir");
      }
  -nodefaultlibs	Do not link against the standard library.
  -std=<std>		Standard to use when building internally with
			GCC for inline assembly. Not used by kcc directly.
  -o <file>		Place the output into <file>.
  -l <lib>		Link semantics against library in search path.
      { RV_Kcc::Opts::classifyLib($lib); }
  -Wl,<args>		Add flags to linker arguments.
      { RV_Kcc::Opts::pushArg('ldArgs', "-Wl,$args"); }
  -u <symbol>		Pretend <symbol> is undefined, to force linking.
      { RV_Kcc::Opts::pushArg('ldArgs', '-u', $symbol); }
  <files>...		C files to be compiled. [repeatable] [required] [undocumented]
      {
            for (@RV_Kcc::Opts::incompleteBreakpoints) {
                  RV_Kcc::Opts::pushArg('breakpoints', [$files[0], $_]);
            }
            for (@files) {
                  classify($_, $RV_Kcc::Opts::xLang);
            }
      }
  -M			Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-M'); }
  -MM			Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-MM'); }
  -MD			Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-MD'); }
  -MMD			Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-MMD'); }
  -MP			Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-MP'); }
  -MF <file>		Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-MF', $file); }
  -MT <target>		Dependency generation. See documentation for GCC
			preprocessor.
      { RV_Kcc::Opts::pushArg('cppArgs', '-MT', $target); }
  -d<chars>		Debugging info from preprocessor. See documentation
			for GCC.
      { RV_Kcc::Opts::pushArg('cppArgs', "-d$chars"); }
  -ftranslation-depth=<depth>	Compile program up to a given depth. [undocumented]
  -fdebug-translation	Run translation semantics with GDB. [undocumented]
  -flinking-depth=<depth>	Link program up to a given depth. [undocumented]
  -fdebug-linking	Run linking semantics with GDB. [undocumented]
  -fmessage-length=0	Write all error messages on a single line.
  -frunner-script	Compile program to perl script with analysis tool options. [undocumented]
  -fissue-report=<file>	Write issues to the specified file.
			Format (CSV/JSON) is inferred from the specified file extension.
  -finteractive-fail	Enter an interactive debugger-like session when
			encountering an otherwise fatal error.
  -fbreakpoint=[<file>:]<line>	Enter an interactive debugger-like session when
			execution reaches a given location in a source file. [repeatable]
      {
            if (defined $file) {
                  RV_Kcc::Opts::pushArg('breakpoints', [$file, $line]);
            } else {
                  push(@RV_Kcc::Opts::incompleteBreakpoints, $line);
            }
      }
  -Wlint		Generate lint errors for potentially undesirable
			behaviors.*
      {
            RV_Kcc::Opts::pushArg('suppressions', '{"condition": ["Category", "LintError"], "suppress": false}');
      }
  -flint		Generate lint errors for potentially undesirable
			behaviors.*
      {
            RV_Kcc::Opts::pushArg('suppressions', '{"condition": ["Category", "LintError"], "suppress": false}');
      }
  -Wno-undefined	Do not output undefined behaviors.*
      {
            RV_Kcc::Opts::pushArg('suppressions',
                  '{"condition": ["Category", ["Undefined", "C"]], "suppress": true},' .
                  '{"condition": ["Category", ["Undefined", "CPP"]], "suppress": true}');
      }
  -Wno-unspecified	Do not output unspecified behaviors.*
      {
            RV_Kcc::Opts::pushArg('suppressions',
                  '{"condition": ["Category", ["Unspecified", "C"]], "suppress": true},' .
                  '{"condition": ["Category", ["Unspecified", "CPP"]], "suppress": true}');
      }
  -Wno-implementation-defined	Do not output implementation-defined behaviors.*
      {
            RV_Kcc::Opts::pushArg('suppressions',
                  '{"condition": ["Category", ["ImplementationDefined", "C"]], "suppress": true},' .
                  '{"condition": ["Category", ["ImplementationDefined", "CPP"]], "suppress": true}');
      }
  -Wno-<errcode>	Ignore specified error code.*
      {
            if ($RV_Kcc::Opts::cppWarns{$errcode}) {
                  RV_Kcc::Opts::pushArg('cppArgs', "-Wno-$errcode");
            } else {
                  RV_Kcc::Opts::pushArg('suppressions', '{"condition": ["ErrorId", "' . $errcode . '"], "suppress": true}');
            }
      }
  -Wsystem-headers	Do not ignore errors in system headers.*
      {
            RV_Kcc::Opts::pushArg('cppArgs', "-Wsystem-headers");
            RV_Kcc::Opts::pushArg('suppressions', '{"condition": ["SystemHeader", true], "suppress": false}');
      }
  -Wfatal-errors	Do not recover from errors reported by tool.*
      {
            RV_Kcc::Opts::pushArg('cppArgs', "-Wfatal-errors");
      }
  -W		[undocumented]
  -W<errcode>		Do not ignore specified error code.*
      {
            if ($RV_Kcc::Opts::cppWarns{$errcode}) {
                  RV_Kcc::Opts::pushArg('cppArgs', "-W$errcode");
            } else {
                  RV_Kcc::Opts::pushArg('suppressions', '{"condition": ["ErrorId", "' . $errcode . '"], "suppress": false}');
            }
      }
  -Wno-ifdef=<macro>	Disable errors on lines emitted when <macro> is
			defined.*
      {
            RV_Kcc::Opts::pushArg('ifdefs', [$macro, "D", "true"]);
      }
  -Wno-ifndef=<macro>	Disable errors on lines emitted when <macro>
 is not
			defined.*
      {
            RV_Kcc::Opts::pushArg('ifdefs', [$macro, "U", "true"]);
      }
  -Wno-file=<glob>	Disable errors in files matching <glob>.*
      {
            RV_Kcc::Opts::pushArg('suppressions', '{"condition": ["File", ' . quote(backslash($glob)) . '], "suppress": true}');
      }
  -no-pedantic		Do not trigger preprocessor warnings for non-standard
			compliant language features.
  -w			Ignore all preprocessor warnings.
      { RV_Kcc::Opts::pushArg('cppArgs', "-w"); }
  -fheap-size=<size>	Used with -flint to detect dynamic memory overflow.*
  -fstack-size=<size>	Used with -flint to detect stack overflow.*
  -frecover-all-errors	Recover from fatal errors that would normally cause an
			application to crash.
			WARNING: This can change the semantics of tools like
			autoconf which analyze the exit code of the compiler to
			trigger unexpected or undesirable results.
  -funresolved-symbols=<method>	Determine how to handle unresolved symbols. Possible values for method:
			ignore-all - Do not report any unresolved symbols.
			warn-all - Report warnings for all unresolved symbols.
			report-all - Report errors for all unresolved symbols.
			warn-unreachable - Report all unresolved symbols.
					Warn if they are not accessible form main(), error otherwise.
					This is the default.
  -fno-native-compilation	Disables compilation of code with native
				compiler in order to improve error reporting in
				programs which fail to compile under the native
				compiler.
				WARNING: Due to technical limitations this also
				disables support for inline assembly.
  -fnative-binary	Build a standalone binary containing only the native code
			needed to execute native functions for the application
			when linking. Slower, but avoids symbol conflicts
			when compiling C code that is part of the RV-Match runtime.
			For the purposes of optimization, you must pass this flag
			during both compilation and linking. [undocumented]
  -fuse-native-std-lib	Use native implementations instead of semantics when
			interpreting calls to standard library functions.
  -fno-diagnostics-color	Disable color in diagnostics.
      { RV_Kcc::Opts::pushArg('cppArgs', '-fno-diagnostics-color'); }
  -x <language>		Set language for input files.
      {
            $RV_Kcc::Opts::xLang = $language;
      }
  -pthread		Enables pthread library (experimental)
      {
            RV_Kcc::Opts::pushArg('cppArgs', '-pthread');
            RV_Kcc::Opts::pushArg('ldArgs', '-lpthread');
      }
  -Xmx<size>		Passed to underlying JVM. [undocumented]
  -profile <name>	Set KCC profile.
      {
            if ( grep( /^$name$/, RV_Kcc::Files::getProfiles() ) ) {
                  open(my $file, '>', RV_Kcc::Files::distDir("current-profile"))
                        or error("Could not open profile file. Check OS permissions.\n");
                  print $file $name;
                  close $file;
                  exit 0;
            } else {
                  print "Profile '$name' is not installed. See " . RV_Kcc::Shell::commandName() . " -v for list of installed profiles.\n";
                  exit 1;
            }
      }
  --use-profile <name>	Use a KCC profile for this run, but do not make it the current profile. [undocumented]
      {
            if ( grep( /^$name$/, RV_Kcc::Files::getProfiles() ) ) {
                  RV_Kcc::Files::currentProfile($name);
            } else {
                  print "Profile '$name' is not installed. See " . RV_Kcc::Shell::commandName() . " -v for list of installed profiles.\n";
                  exit 1;
            }
      }
  --no-license-message	Do not print any licensing information. Use this
                        option if extra output interferes with a build system.
                        Setting the environment error KCC_NO_LICENCE_MESSAGE
                        has the same effect.
  -Xk++			[undocumented]
  -soname <name>	[undocumented]

  * Indicates flags that require RV-Match from
    http://www.runtimeverification.com/match to run.

  For a complete list of other flags ignored by ! . RV_Kcc::Shell::commandName() . ", refer to\n  " . distDir('ignored-flags') . q!/,
  which contains one regular expression per line.

  The following lines of output are added to this message for compatibility
  with GNU ld and libtool:

  : supported targets: elf
=cut
}

1;
