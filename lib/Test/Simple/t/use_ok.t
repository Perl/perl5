BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

use Test::More tests => 7;

# Using Symbol because it's core and exports lots of stuff.
{
    package Foo::one;
    ::use_ok("Symbol");
    ::ok( defined &gensym,        'use_ok() no args exports defaults' );
}

{
    package Foo::two;
    ::use_ok("Symbol", qw(qualify));
    ::ok( !defined &gensym,       '  one arg, defaults overriden' );
    ::ok( defined &qualify,       '  right function exported' );
}

{
    package Foo::three;
    ::use_ok("Symbol", qw(gensym ungensym));
    ::ok( defined &gensym && defined &ungensym,   '  multiple args' );
}
