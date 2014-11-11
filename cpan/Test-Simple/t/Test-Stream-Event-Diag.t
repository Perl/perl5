use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'Test::Stream::Event::Diag';

my $ctx = context(-1); my $line = __LINE__;
$ctx = $ctx->snapshot;
is($ctx->line, $line, "usable context");

my $diag = $ctx->diag('hello');
ok($diag, "build diag");
isa_ok($diag, 'Test::Stream::Event::Diag');
is($diag->message, 'hello', "message");

is_deeply(
    [$diag->to_tap],
    [[Test::Stream::Event::Diag::OUT_ERR, "# hello\n"]],
    "Got tap"
);

done_testing;
