use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Formatter';

can_ok('Test::Builder::Formatter', qw/new handle to_handler/);

my $one = Test::Builder::Formatter->new;
isa_ok($one, 'Test::Builder::Formatter');

my $ref = ref $one->to_handler;
is($ref, 'CODE', 'handler returns a coderef');

{
    package My::Listener;

    use base 'Test::Builder::Formatter';

    sub ok { $main::SEEN++ }
}

My::Listener->listen;

ok(1, "Just a result");
is($main::SEEN, 1, "Listener saw the result");

ok(1, "Just a result");
is($main::SEEN, 3, "Listener saw the other results too");

done_testing;
