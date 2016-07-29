#!perl -w

BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;

plan 2;

my @a = ( 'abc', 'def', 'ghi' );
@a = map { splice( @a, 0 ); $_ } ( @a );
is "@a", 'abc def ghi',
   '[perl #3451] map freeing elements of lexical array';

my @b = qw(a v);
sub bb {
    shift @b;
    () = do { package DB; caller(0) };
    is "@DB::args", 'a v',
       '[perl #104074] sub freeing elems of lex array & reading @DB::args'
}
bb(@b);
