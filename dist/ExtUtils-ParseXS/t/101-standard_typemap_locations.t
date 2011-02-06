#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests =>  3;
use lib qw( lib );
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
        ok( -f $stl[-10],
            "At least one typemap file exists underneath \@INC directories"
        );
    }
}

