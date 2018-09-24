package RV_Kcc::Files;

use v5.10;
use strict;
use warnings;

use File::Basename;
use File::Temp qw(tempfile tempdir);
use File::Spec::Functions qw(rel2abs catfile);
use Exporter;

our $VERSION = 1.00;
our @ISA = qw(Exporter);
our @EXPORT = qw();
our @EXPORT_OK = qw(
      profileDir
      distDir
      currentProfile
      defaultProfile
      getProfiles
      tempFile
      tempDir
      error
      IS_CYGWIN
);

use constant IS_CYGWIN    => $^O eq "cygwin" || $^O eq "msys";

sub distDir {
      state $distDirectory = do {
            my $d = dirname(rel2abs($0));
            if (IS_CYGWIN) {
                  $d = shell("cygpath -w $d")->stdout()->run();
                  chop($d);
            }
            $d;
      };

      return catfile($distDirectory, @_);
}

sub currentProfile {
      state $profile;
      if (scalar @_) {
            ($profile) = @_;
      }
      $profile ||= do {
            local $/ = undef;
            open my $fh, '<', distDir('current-profile')
                  or error("Couldn't find current profile: please fix " . distDir('current-profile') . ".\n");
            <$fh>;
      };
      return $profile;
}

sub defaultProfile {
      state $profile;
      if (scalar @_) {
            ($profile) = @_;
      }
      $profile ||= do {
            local $/ = undef;
            open my $fh, '<', distDir('default-profile')
                  or error("Couldn't find default profile: please fix " . distDir('default-profile') . ".\n");
            <$fh>;
      };
      return $profile;
}

sub profilesDir {
      state $profs = do {
            my $d = distDir('profiles');
            if (IS_CYGWIN) {
                  $d = shell("cygpath -w $d")->stdout()->run();
                  chop($d);
            }
            $d;
      };

      return catfile($profs, @_);
}

sub profileDir {
      state $prof = do {
            my $d = profilesDir(currentProfile());
            if (IS_CYGWIN) {
                  $d = shell("cygpath -w $d")->stdout()->run();
                  chop($d);
            }
            $d;
      };

      return catfile($prof, @_);
}

sub getProfiles {
      state @profiles;
      state $profilesInitialized;
      if (!$profilesInitialized) {
            @profiles = do {
                  opendir (my $DIR, profilesDir());
                  my @p = ();
                  while (my $entry = readdir $DIR) {
                        next unless -d profilesDir($entry);
                        next if $entry eq '.' or $entry eq '..';
                        push(@p, $entry);
                  }
                  @p;
            };
            $profilesInitialized = 1;
      }

      return @profiles;
}

{
      my $tempRoot = rel2abs(tempdir(".tmp-kcc-XXXXX", CLEANUP => 1));

      sub tempFile {
            my ($name, $ext) = @_;

            my $file;
            if (defined $ext) {
                  (undef, $file) = tempfile(catfile($tempRoot, "$name-XXXXX"), UNLINK => 1, OPEN => 0, SUFFIX => $ext);
            } else {
                  (undef, $file) = tempfile(catfile($tempRoot, "$name-XXXXX"), UNLINK => 1, OPEN => 0);
            }
            return $file;
      }

      sub tempDir {
            my ($name) = @_;

            my $dir = tempdir(catfile($tempRoot, "tmp-kcc-$name-XXXXX"), CLEANUP => 1);

            return $dir;
      }
}

sub error {
      print STDERR @_;
      exit 1;
}

1;
