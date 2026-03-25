#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

# Basic role definition with field and method
{
    role Describable {
        field $description :param;

        method describe { return $description }
    }

    isa_ok('Describable', 'UNIVERSAL');
    ok(Describable->can('describe'), 'role has describe method');

    # Roles should not be directly instantiable (no new)
    ok(!Describable->can('new'), 'role has no constructor');
}

# Role with multiple fields and methods
{
    role Positioned {
        field $x :param = 0;
        field $y :param = 0;

        method x { return $x }
        method y { return $y }
        method position { return "$x,$y" }
    }

    ok(Positioned->can('x'), 'role has x method');
    ok(Positioned->can('y'), 'role has y method');
    ok(Positioned->can('position'), 'role has position method');
}

# Roles cannot use :isa
{
    ok(!eval q{
        use v5.36;
        use feature 'class';
        no warnings 'experimental::class';
        role BadRole :isa(UNIVERSAL) { }
        1;
    }, 'role with :isa fails');
    like($@, qr/Roles cannot use :isa/, 'correct error for :isa on role');
}

# Role with ADJUST block
{
    role WithAdjust {
        field $adjusted :reader = 0;

        ADJUST {
            $adjusted = 1;
        }
    }

    ok(1, 'role with ADJUST block compiles');
}

# Role with :reader and :writer attributes
{
    role Named {
        field $name :param :reader;
    }

    ok(Named->can('name'), 'role has reader method');
}

done_testing;
