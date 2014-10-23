use strict;
use warnings;

use Test::Stream;
use Test::MostlyLike;
use Test::More;

use ok 'Test::Stream::IOSets';

my ($out, $err) = Test::Stream::IOSets->open_handles;
ok($out && $err, "got 2 handles");
ok(close($out), "Close stdout");
ok(close($err), "Close stderr");

my $one = Test::Stream::IOSets->new;
isa_ok($one, 'Test::Stream::IOSets');
mostly_like(
    $one,
    { ':legacy' => [], ':utf8' => undef },
    "Legacy encoding is set",
);

ok($one->init_encoding('utf8'), "init utf8");

mostly_like(
    $one,
    { ':legacy' => [], ':utf8' => [] },
    "utf8 encoding is set",
);

done_testing;
