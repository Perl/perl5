#!/usr/bin/perl -w
# $Id: /mirror/googlecode/test-more/t/plan_shouldnt_import.t 57943 2008-08-18T02:09:22.275428Z brooklyn.kid51  $

# plan() used to export functions by mistake [rt.cpan.org 8385]

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}


use Test::More ();
Test::More::plan(tests => 1);

Test::More::ok( !__PACKAGE__->can('ok'), 'plan should not export' );
