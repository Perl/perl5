use strict;
use warnings;

use Test::Stream;
use Test::More;
use Scalar::Util qw/dualvar/;

use ok 'Test::Stream::Util', qw{
    try protect spoof is_regex is_dualvar
};

can_ok(__PACKAGE__, qw{
    try protect spoof is_regex is_dualvar
});

my $x = dualvar( 100, 'one-hundred' );
ok(is_dualvar($x), "Got dual var");
$x = 1;
ok(!is_dualvar($x), "Not dual var");

$! = 100;

my $ok = eval { protect { die "xxx" }; 1 };
ok(!$ok, "protect did not capture exception");
like($@, qr/xxx/, "expected exception");

cmp_ok($!, '==', 100, "\$! did not change");
$@ = 'foo';

($ok, my $err) = try { die "xxx" };
ok(!$ok, "cought exception");
like( $err, qr/xxx/, "expected exception");
is($@, 'foo', '$@ is saved');
cmp_ok($!, '==', 100, "\$! did not change");

ok(is_regex(qr/foo bar baz/), 'qr regex');
ok(is_regex('/xxx/'), 'slash regex');
ok(!is_regex('xxx'), 'not a regex');

my ($ret, $e) = spoof ["The::Moon", "Moon.pm", 11] => "die 'xxx' . __PACKAGE__";
ok(!$ret, "Failed eval");
like( $e, qr/^xxxThe::Moon at Moon\.pm line 11\.?/, "Used correct package, file, and line");


done_testing;
