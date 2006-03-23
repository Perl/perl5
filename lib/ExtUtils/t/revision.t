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

use Test::More tests => 4;

BEGIN { 
    use_ok 'ExtUtils::MakeMaker'; 
    use_ok 'ExtUtils::MM_VMS';
}

like $ExtUtils::MakeMaker::Revision, qr/^(\d)+$/;
like $ExtUtils::MM_VMS::Revision, qr/^(\d)+$/;
