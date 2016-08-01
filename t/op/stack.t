#!perl -w

BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;

plan 4;

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

our @X = qw/ A B C D E /;
sub F {
    @X = ();
    our @Y = qw/ magic /;
    is join(',', @_), "start,A,B,C,D,E,end",
      '[perl #8358] sub freeing elems of pkg array';
}
F('start', @X, 'end');

our @files = (1,2);
eval { for (sort @files) { @files = (); } };
is $@, '', '[perl #18489] freeing elems of sort @pkg_array';
