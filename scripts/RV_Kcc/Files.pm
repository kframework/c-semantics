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
      currentHardwareAddresses
      currentProfile
      defaultHardwareAddresses
      defaultProfile
      distDir
      error
      getProfiles
      getHardwareAddresses
      IS_CYGWIN
      kBinDir
      nativeCC
      nativeCXX
      profileDir
      hardwareAddressesFile
      tempDir
      tempFile
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
      my $prof = profilesDir(currentProfile());
      if (IS_CYGWIN) {
            $prof = shell("cygpath -w $prof")->stdout()->run();
            chop($prof);
      }

      return catfile($prof, @_);
}

sub hardwareAddressesDir {
      state $profs = do {
            my $d = distDir('hardware-addresses');
            if (IS_CYGWIN) {
                  $d = shell("cygpath -w $d")->stdout()->run();
                  chop($d);
            }
            $d;
      };

      return catfile($profs, @_);
}

sub hardwareAddressesFile {
      my $prof = hardwareAddressesDir(currentHardwareAddresses());
      if (IS_CYGWIN) {
            $prof = shell("cygpath -w $prof")->stdout()->run();
            chop($prof);
      }

      return catfile($prof, @_);
}

sub currentHardwareAddresses {
      state $profile;
      if (scalar @_) {
            ($profile) = @_;
      }
      $profile ||= do {
            local $/ = undef;
            open my $fh, '<', distDir('current-hardware-addresses')
                  or error("Couldn't find current hardware addresses: please fix " . distDir('current-hardware-addresses') . ".\n");
            <$fh>;
      };
      return $profile;
}

sub defaultHardwareAddresses {
      state $profile;
      if (scalar @_) {
            ($profile) = @_;
      }
      $profile ||= do {
            local $/ = undef;
            open my $fh, '<', distDir('default-hardware-addresses')
                  or error("Couldn't find default hardware addresses profile: please fix " . distDir('default-hardware-addresses') . ".\n");
            <$fh>;
      };
      return $profile;
}

sub kBinDir {
      my $path = defined($ENV{'K_BIN'})? $ENV{'K_BIN'} : distDir('k', 'bin');
      if (IS_CYGWIN) {
            $path = shell("cygpath -w $path")->stdout()->run();
            chop($path);
      }

      return catfile($path, @_);
}

sub nativeCC {
      return profileDir("cc");
}

sub nativeCXX {
      return profileDir("cxx");
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

sub getHardwareAddresses {
      state @profiles;
      state $profilesInitialized;
      if (!$profilesInitialized) {
            @profiles = do {
                  opendir (my $DIR, hardwareAddressesDir());
                  my @p = ();
                  while (my $entry = readdir $DIR) {
                        next unless -f hardwareAddressesDir($entry);
                        push(@p, $entry);
                  }
                  @p;
            };
            $profilesInitialized = 1;
      }

      return @profiles;
}

{
      my $tempRoot = tempdir(".tmp-kcc-XXXXX", CLEANUP => 1);

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
