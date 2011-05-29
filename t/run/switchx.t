#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

require './test.pl';

# Test '-x'
print runperl( switches => ['-x'],
               progfile => 'run/switchx.aux' );

# Test '-xdir'
print runperl( switches => ['-x./run'],
               progfile => 'run/switchx2.aux',
               args     => [ 3 ] );

# EOF
