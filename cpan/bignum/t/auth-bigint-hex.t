#!perl

BEGIN {
    unless ($ENV{AUTHOR_TESTING}) {
        require Test::More;
        Test::More::plan(skip_all => 'these tests are for release candidate testing');
    }
}

use strict;
use warnings;

use Test::More tests => 507068;

use Algorithm::Combinatorics qw< variations >;

use bigint;

use Test::More;

my $elements = ['0', 'b', 'x', '1', '1', '_', '_', '9', 'z'];

for my $k (0 .. @$elements) {
    my $seen = {};
    for my $variation (variations($elements, $k)) {
        my $str = join "", @$variation;
        next if $seen -> {$str}++;
        print qq|#\n# hex("$str")\n#\n|;

        my $i;
        my @warnings;
        local $SIG{__WARN__} = sub {
            my $warning = shift;
            $warning =~ s/ at .*\z//s;
            $warnings[$i] = $warning;
        };

        $i = 0;
        my $want_val  = CORE::hex("$str");
        my $want_warn = $warnings[$i];

        $i = 1;
        my $got_val   = bigint::hex("$str");
        my $got_warn  = $warnings[$i];

        is($got_val,  $want_val,  qq|hex("$str") (output)|);
        is($got_warn, $want_warn, qq|hex("$str") (warning)|);
    }
}
