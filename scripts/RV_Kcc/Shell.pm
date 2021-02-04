package RV_Kcc::Shell;

use v5.10;
use strict;
use warnings;

use Cwd qw(getcwd);
use File::Basename qw(basename);
use File::Copy qw(copy);
use File::Spec::Functions qw(catfile);
use String::ShellQuote qw(shell_quote_best_effort);
use Exporter;

use RV_Kcc::Files qw(tempFile kBinDir IS_CYGWIN);

use constant NULL => '/dev/null';

use constant KBIN2TEXT         => do {
	my $path = kBinDir('k-bin-to-text');
	my $ext = IS_CYGWIN? '.bat' : '';
	$path . $ext;
};

our $VERSION = 1.00;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
      checkError
      commandName
      enableDebugging
      saveArgv
      setShellDebugFile
      shell
      debug
);

my $debugging = 0;

sub enableDebugging {
      $File::Temp::KEEP_ALL = 1;
      $debugging = 1;
}

sub debug {
      if ($debugging) {
            print "DEBUG> ";
            print @_;
      }
}

sub shell {
      my ($cmd, @args) = @_;
      my $self =
            { CMD => $cmd
            , ARGS => \@args
            , STDOUT => NULL
            , STDERR => NULL
            , TMP => ''
            };
      return (bless $self);
}

sub verbose {
      my ($self) = @_;
      $self->{STDOUT} = '';
      $self->{STDERR} = '';
      $self->{TMP} = '';
      return $self;
}

sub append {
      my ($self, @args) = @_;
      $self->{ARGS} = [@{$self->{ARGS}}, @args];
      return $self;
}

sub stdout {
      my ($self, @file) = @_;
      if (!@file) {
            $self->{TMP} ||= tempFile('shell');
            $self->{STDOUT} = $self->{TMP};
      } else {
            $self->{STDOUT} = catfile(@file);
      }
      return $self;
}

sub stderr {
      my ($self, @file) = @_;
      if (!@file) {
            $self->{TMP} ||= tempFile('shell');
            $self->{STDERR} = $self->{TMP};
      } else {
            $self->{STDERR} = catfile(@file);
      }
      return $self;
}

sub result {
      my ($self) = @_;

      my $cmd = join(' ', ($self->{CMD}, (map {shell_quote_best_effort($_)} @{$self->{ARGS}})));

      if ($debugging) {
            $self->{STDOUT} eq NULL and $self->{STDOUT} = '';
            $self->{STDERR} eq NULL and $self->{STDERR} = '';
      }

      if ($self->{STDOUT} || $self->{STDERR}) {
            $cmd = "($cmd)";
            $self->{STDOUT} and $cmd = "$cmd 1>$self->{STDOUT}";
            $self->{STDERR} and $cmd = "$cmd 2>$self->{STDERR}";
      }

      debug("Executing: $cmd\n");

      system($cmd);
      my $r = $? >> 8;

      debug("(Result: $r)\n");

      return $r;
}

sub run {
      my ($self, @args) = @_;

      checkError(result(@_));

      if ($self->{TMP}) {
            my $output = '';
            do {
                  local $/ = undef;
                  if (open my $fh, '<', $self->{TMP}) {
                        $output = <$fh>;
                  }
            };
            return $output;
      }

      return '';
}

sub commandName {
      if (defined $ENV{KCC_COMMAND_NAME}) {
            return $ENV{KCC_COMMAND_NAME};
      } else {
            return basename($0);
      }
}

{
      my $debugFile;
      my $isBinary;
      my @savedArgv;

      sub saveArgv {
            @savedArgv = @ARGV;
            if (defined $savedArgv[-1] && $savedArgv[-1] eq '-Xk++') {
                  # special case for k++ wrapper script which we don't want
                  # to display as an argument
                  pop(@savedArgv);
            }
      }

      sub setShellDebugFile {
            ($debugFile, $isBinary) = @_;
      }

      sub checkError {
            my ($retval) = @_;
            if ($retval) {
                  if ($debugFile && $isBinary) {
                        copy($debugFile, 'kcc_config.bin');
                        shell(KBIN2TEXT, $debugFile, 'kcc_config')->result();
                  } elsif ($debugFile) {
                        copy($debugFile, 'kcc_config');
                  }
                  print STDERR "Translation failed";
                  if ($debugFile && -e 'kcc_config') {
                        print STDERR " (kcc_config dumped). ";
                  } else {
                        print STDERR ". ";
                  }
                  if ($debugging) {
                        print STDERR "Refer to last command run for details.\n";
                        exit $retval;
                  } else {
                        my $dir = basename(getcwd());
                        print STDERR "To repeat, run this command in directory $dir:\n", commandName(), " -d @savedArgv\n";
                        exit $retval;
                  }
            }
      }
}

1;
