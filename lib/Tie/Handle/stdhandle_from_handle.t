#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 1;

use Tie::Handle;

{
    package Foo;
    our @ISA = qw(Tie::StdHandle);
}

# For backwards compatibility with 5.8.x
ok( Foo->can("TIEHANDLE"), "loading Tie::Handle loads TieStdHandle" );
