#!./perl

BEGIN {
    $| = 1;
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc( '../lib' );
    plan (tests => 2); # some tests are run in BEGIN block
}

$0 = 'z';
is( $0, 'z' );

SKIP: {
    skip "Test is for Linux, not $^O", 1 if $^O ne 'linux';

    my $got = `cat /proc/$$/cmdline`;
    is( $got, "z\0", 'expected output' );
}

