my $module = join(" ", <>); # read from stdin or filename passed to script

$module =~ s/eq \(numBitsPerByte\).NzNat = ([^[]+) \[.*// or die "Couldn't find numBitsPerByte";
my $numBitsPerByte = $1;
$module =~ s/\(numBitsPerByte\).NzNat/$numBitsPerByte/g;

# $module =~ s/eq _`\(_`\)\(\('cfg:largestUnsigned\)\.KResultLabel, \(\.List`\{K`\}\)\.List`\{KResult`\}\) = ([^[]+) \[.*// or die "Couldn't find largestunsigned";
# my $numBitsPerByte = $1;
# $module =~ s/_`\(_`\)\(\('cfg:largestUnsigned\)\.KResultLabel, \(\.List`\{K`\}\)\.List`\{KResult`\}\)/$largestunsigned/g;

print $module;


# would be nice to see how many times semantics visits a line of code