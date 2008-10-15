#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/tbm_doesnt_set_exported_to.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use strict;
use warnings;

# Can't use Test::More, that would set exported_to()
use Test::Builder;
use Test::Builder::Module;

my $TB = Test::Builder->create;
$TB->plan( tests => 1 );
$TB->level(0);

$TB->is_eq( Test::Builder::Module->builder->exported_to,
            undef,
            'using Test::Builder::Module does not set exported_to()'
);
