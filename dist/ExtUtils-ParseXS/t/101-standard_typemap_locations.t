#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests =>  5;
use ExtUtils::ParseXS::Utilities qw(
  standard_typemap_locations
);

{
    local @INC = @INC;
    my @stl = standard_typemap_locations( \@INC );
    ok( @stl >= 9, "At least 9 entries in typemap locations list" );
    is( $stl[$#stl], 'typemap',
        "Last element is typemap in current directory");
    SKIP: {
        skip "No lib/ExtUtils/ directories under directories in \@INC",
        1
        unless @stl > 9;

        # Check that at least one typemap file can be found under @INC
        my $max = $#INC;
        ok(
            ( 0 < (grep -f $_, @stl[0..$max]) ),
            "At least one typemap file exists underneath \@INC directories"
        );
    }
}

{
    my @fake_INC = qw(a/b/c  d/e/f  /g/h/i);
    my @expected =
        (
            map("$_/ExtUtils/typemap", reverse @fake_INC),
            qw(
                ../../../../lib/ExtUtils/typemap
                ../../../../typemap
                ../../../lib/ExtUtils/typemap
                ../../../typemap
                ../../lib/ExtUtils/typemap
                ../../typemap
                ../lib/ExtUtils/typemap
                ../typemap
                typemap
            )
        );

    my @stl = standard_typemap_locations( \@fake_INC );

    is(scalar @stl, scalar @expected,
        "with fake INC: corrrect number of entries in typemap locations list" );

    SKIP: {
        # Only do a full string comparison on platforms which handle
        # "standard" pathname formats and '..' updirs. We *always* test
        # on linux, and otherwise test unless the second from last doesn't
        # look standard. Always testing on Linux means there is at least
        # one platform that won't falsely skip the test if garbage is
        # returned.
        skip "platform doesn't use ../..", 1
            if      $^O ne 'linux'
               and  $stl[-2] ne '../typemap';

        is_deeply(\@stl, \@expected, "with fake INC: list of paths match");
    }
}

