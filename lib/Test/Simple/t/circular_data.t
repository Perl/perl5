#!/usr/bin/perl -w

# Test is_deeply and friends with circular data structures [rt.cpan.org 7289]

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;
use Test::More tests => 5;

my $a1 = [ 1, 2, 3 ];
push @$a1, $a1;
my $a2 = [ 1, 2, 3 ];
push @$a2, $a2;

is_deeply $a1, $a2;
ok( eq_array ($a1, $a2) );
ok( eq_set   ($a1, $a2) );

my $h1 = { 1=>1, 2=>2, 3=>3 };
$h1->{4} = $h1;
my $h2 = { 1=>1, 2=>2, 3=>3 };
$h2->{4} = $h2;

is_deeply $h1, $h2;
ok( eq_hash  ($h1, $h2) );
