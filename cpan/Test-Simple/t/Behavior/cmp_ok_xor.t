use strict;
use warnings;

use Test::Stream;
use Test::More;

my @warnings;
$SIG{__WARN__} = sub { push @warnings => @_ };
my $ok = cmp_ok( 1, 'xor', 0, 'use xor in cmp_ok' );
ok(!@warnings, "no warnings");
ok($ok, "returned true");

done_testing;
