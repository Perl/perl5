#!perl

# This script tests not only the interface for XS AUTOLOAD routines to find
# out the sub name, but also that that interface does not interfere with
# prototypes, the way it did before 5.15.4.

use strict;
use warnings;

use Test::More tests => 14;

use XS::APItest;

is XS::APItest::AutoLoader::frob(), 'frob', 'name passed to XS AUTOLOAD';
is "XS::APItest::AutoLoader::fr\0b"->(), "fr\0b",
  'name with embedded null passed to XS AUTOLOAD';
is "XS::APItest::AutoLoader::fr\x{1ed9}b"->(), "fr\x{1ed9}b",
  'Unicode name passed to XS AUTOLOAD';

*AUTOLOAD = *XS::APItest::AutoLoader::AUTOLOADp;

is frob(), 'frob', 'name passed to XS AUTOLOAD with proto';
is prototype \&AUTOLOAD, '*$', 'prototype is unchanged';
is "fr\0b"->(), "fr\0b",
  'name with embedded null passed to XS AUTOLOAD with proto';
is prototype \&AUTOLOAD, '*$', 'proto unchanged after embedded-null call';
is "fr\x{1ed9}b"->(), "fr\x{1ed9}b",
  'Unicode name passed to XS AUTOLOAD with proto';
is prototype \&AUTOLOAD, '*$', 'prototype is unchanged after Unicode call';

# Test that the prototype was preserved from the parser’s point of view

ok !eval "sub { ::AUTOLOAD(1) }",
   'parse failure due to AUTOLOAD prototype';
ok eval "sub { ::AUTOLOAD(1,2) }", 'successful parse respecting prototype'
  or diag $@;

package fribble { sub a { return 7 } }
no warnings 'once';
*a = \&AUTOLOAD;
'$'->();
# &a('fribble') will return '$'
# But if intuit_method does not see the (*...) proto, this compiles as
# fribble->a
no strict;
is eval 'a fribble, 3', '$', 'intuit_method sees * in AUTOLOAD proto'
  or diag $@;

# precedence check
# *$ should parse as a list operator, but right now the AUTOLOAD
# sub name is $
is join(" ", eval 'a "b", "c"'), '$',
   'precedence determination respects prototype of AUTOLOAD sub';

{
    my $w;
    local $SIG{__WARN__} = sub { $w .= shift };
    eval 'sub a($){}';
    like $w, qr/^Prototype mismatch: sub main::a \(\*\$\) vs \(\$\)/m,
        'proto warnings respect AUTOLOAD prototypes';
}
