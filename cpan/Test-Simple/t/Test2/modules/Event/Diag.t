use strict;
use warnings;
BEGIN { require "t/tools.pl" };
use Test2::Event::Diag;
use Test2::Util::Trace;

my $diag = Test2::Event::Diag->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => 'foo',
);

is($diag->summary, 'foo', "summary is just message");

$diag = Test2::Event::Diag->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => undef,
);

is($diag->message, 'undef', "set undef message to undef");
is($diag->summary, 'undef', "summary is just message even when undef");

$diag = Test2::Event::Diag->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    message => {},
);

like($diag->message, qr/^HASH\(.*\)$/, "stringified the input value");

ok($diag->diagnostics, "Diag events are counted as diagnostics");

done_testing;
