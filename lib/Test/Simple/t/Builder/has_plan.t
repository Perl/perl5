#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/Builder/has_plan.t 60332 2008-09-09T12:24:03.060291Z schwern  $

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib');
    }
}

use strict;
use Test::Builder;

my $unplanned;

BEGIN {
	$unplanned = 'oops';
	$unplanned = Test::Builder->new->has_plan;
};

use Test::More tests => 2;

is($unplanned, undef, 'no plan yet defined');
is(Test::Builder->new->has_plan, 2, 'has fixed plan');
