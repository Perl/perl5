#!./perl

# Ensure that the -P and -x flags work together.

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

require './test.pl';

print runperl( switches => ['-Px'], 
               nolib => 1,   # for some reason this is necessary under VMS
               progfile => 'run/switchPx.aux' );
