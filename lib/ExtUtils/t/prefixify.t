#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't' if -d 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;
use Test::More tests => 1;
use File::Spec;
use ExtUtils::MM;

my $mm = bless {}, 'MM';

my $default = File::Spec->catdir(qw(this that));
$mm->prefixify('installbin', 'wibble', 'something', $default);
               
is( $mm->{INSTALLBIN}, File::Spec->catdir('something', $default),
                                            'prefixify w/defaults');
