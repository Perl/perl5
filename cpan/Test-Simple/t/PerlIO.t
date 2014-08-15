use Test::More 'modern';
require PerlIO;

my $ok = 1;
my %counts;
for my $layer (PerlIO::get_layers(__PACKAGE__->TB_INSTANCE()->stream->tap->output)) {
    my $dup = $counts{$layer}++;
    ok(!$dup, "No IO layer duplication '$layer'");
}

done_testing;
