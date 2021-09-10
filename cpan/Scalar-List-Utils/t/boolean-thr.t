#!./perl

use strict;
use warnings;

use Config ();
use Scalar::Util ();
use Test::More
    (grep { /isbool/ } @Scalar::Util::EXPORT_FAIL) ? (skip_all => 'isbool is not supported on this perl') :
    (!$Config::Config{usethreads})                 ? (skip_all => 'perl does not support threads') :
    (tests => 5);

use threads;
use threads::shared;

Scalar::Util->import("isbool");

ok(threads->create( sub { isbool($_[0]) }, !!0 )->join,
    'value in to thread is bool');

ok(isbool(threads->create( sub { return !!0 } )->join),
    'value out of thread is bool');

{
    my $var = !!0;
    ok(threads->create( sub { isbool($var) } )->join,
        'variable captured by thread is bool');
}

{
    my $sharedvar :shared = !!0;

    ok(isbool($sharedvar),
        ':shared variable is bool outside');

    ok(threads->create( sub { isbool($sharedvar) } )->join,
        ':shared variable is bool inside thread');
}
