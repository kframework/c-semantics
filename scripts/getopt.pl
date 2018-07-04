use Getopt::Declare;

# generate getopt declare code
sub encode { return Getopt::Declare->new(shift,-BUILD)->code() || die }

sub classify { }

# read kcc script from stdin
my $kcc = do { local $/; <STDIN> };
# look for getopt declare specification in code and replace it with the code that
# executes the actual parsing
$kcc =~ s/^=for\s+Getopt::Declare\s*\n(.*?)\n=cut/'$self->{_internal}{usage} = q!
' . $1 . '
!;
'.encode($1).''/esm; 

print $kcc;
