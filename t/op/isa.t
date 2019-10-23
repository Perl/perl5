#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use strict;
use feature 'isa';

plan 9;

package BaseClass {}
package DerivedClass { our @ISA = qw(BaseClass) }

my $baseobj = bless {}, "BaseClass";
my $derivedobj = bless {}, "DerivedClass";

# Bareword package name
ok($baseobj isa BaseClass, '$baseobj isa BaseClass');
ok(not($baseobj isa Another::Class), '$baseobj is not Another::Class');

# String package name
ok($baseobj isa "BaseClass",         '$baseobj isa BaseClass');
ok(not($baseobj isa "DerivedClass"), '$baseobj is not DerivedClass');

ok($derivedobj isa "DerivedClass", '$derivedobj isa DerivedClass');
ok($derivedobj isa "BaseClass",    '$derivedobj isa BaseClass');

# Expression giving a package name
my $classname = "DerivedClass";
ok($derivedobj isa $classname, '$derivedobj isa DerivedClass via SV');

ok(not(undef isa "BaseClass"), 'undef is not BaseClass');
ok(not([] isa "BaseClass"),    'ARRAYref is not BaseClass');

# TODO: Consider 
#    LHS = other class
