#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = qw(../lib);
}

require "./test.pl";

plan( tests => 1 );

# Used to segfault (bug #15479)
fresh_perl_is(
    '%:: = ""',
    'Odd number of elements in hash assignment at - line 1.',
    { switches => [ '-w' ] },
    'delete $::{STDERR} and print a warning',
);
