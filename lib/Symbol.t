#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 10;

BEGIN { $_ = 'foo'; }  # because Symbol used to clobber $_

use Symbol;

ok( $_ eq 'foo', 'check $_ clobbering' );


# First test gensym()
$sym1 = gensym;
ok( ref($sym1) eq 'GLOB', 'gensym() returns a GLOB' );

$sym2 = gensym;

ok( $sym1 ne $sym2, 'gensym() returns a different GLOB' );

ungensym $sym1;

$sym1 = $sym2 = undef;


# Test qualify()
package foo;

use Symbol qw(qualify);  # must import into this package too

::ok( qualify("x") eq "foo::x",		'qualify() with a simple identifier' );
::ok( qualify("x", "FOO") eq "FOO::x",	'qualify() with a package' );
::ok( qualify("BAR::x") eq "BAR::x",
    'qualify() with a qualified identifier' );
::ok( qualify("STDOUT") eq "main::STDOUT",
    'qualify() with a reserved identifier' );
::ok( qualify("ARGV", "FOO") eq "main::ARGV",
    'qualify() with a reserved identifier and a package' );
::ok( qualify("_foo") eq "foo::_foo",
    'qualify() with an identifier starting with a _' );
::ok( qualify("^FOO") eq "main::\cFOO",
    'qualify() with an identifier starting with a ^' );
