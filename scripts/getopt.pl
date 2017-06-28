use Getopt::Declare;

sub encode { return Getopt::Declare->new(shift,-BUILD)->code() || die }

sub classify {}

my $kcc = do { local $/; <STDIN> };
$kcc =~ s/^=for\s+Getopt::Declare\s*\n(.*?)\n=cut/'$self->{_internal}{usage} = q(
' . $1 . '
);
'.encode($1).''/esm; 

print $kcc;
