#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

require './test.pl';

print runperl( switches => ['-x'], progfile => 'run/switchx.aux' );
