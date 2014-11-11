use Test::More;
require PerlIO;

my $ok = 1;
my %counts;
for my $layer (PerlIO::get_layers(Test::Stream->shared->io_sets->{legacy}->[0])) {
    my $dup = $counts{$layer}++;
    ok(!$dup, "No IO layer duplication '$layer'");
}

done_testing;
