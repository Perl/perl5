BEGIN {
    if ($ENV{PERL_CORE}) {
	chdir 't' if -d 't';
	@INC = ("../lib", "lib/compress");
    }
}

use lib qw(t t/compress);
use strict;
use warnings;

use Test::More ;

BEGIN {
    plan skip_all => "Lengthy Tests Disabled\n" .
                     "set COMPRESS_ZLIB_RUN_ALL or COMPRESS_ZLIB_RUN_MOST to run this test suite"
        unless defined $ENV{COMPRESS_ZLIB_RUN_ALL} or defined $ENV{COMPRESS_ZLIB_RUN_MOST};
    
    # use Test::NoWarnings, if available
    my $extra = 0 ;
    $extra = 1
        if eval { require Test::NoWarnings ;  import Test::NoWarnings; 1 };

    plan tests => 2552 + $extra;

};


#use Test::More skip_all => "not implemented yet";


use IO::Compress::Deflate   qw($DeflateError) ;
use IO::Uncompress::Inflate qw($InflateError) ;

sub identify
{
    'IO::Compress::Deflate';
}

require "truncate.pl" ;
run();
