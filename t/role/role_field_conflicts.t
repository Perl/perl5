#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.42;
use feature 'class';
no warnings 'experimental::class';

# Field conflict between two roles - always an error
{
    role FA1 { field $x :param; }
    role FB1 { field $x :param; }

    eval q{
        class FC1 :does(FA1) :does(FB1) { }
    };
    like($@, qr/Field.*\$x.*conflicts/i, "field conflict detected between two roles");
}

# Diamond field composition - no conflict (same origin)
# Note: :param fields in diamond case have a known limitation with
# param deletion, so we test with a non-param field + default.
{
    role FBase2 { field $x = 42; field $y :reader; method get_x { $x } }
    role FLeft2 :does(FBase2) { }
    role FRight2 :does(FBase2) { }

    class FC2 :does(FLeft2) :does(FRight2) { }
    is(FC2->new->get_x, 42, "diamond field - no conflict, default works");
}

# Field + method conflicts reported together in batch
{
    role FA3 { field $x :param; method m { 1 } }
    role FB3 { field $x :param; method m { 2 } }

    eval q{
        class FC3 :does(FA3) :does(FB3) { }
    };
    like($@, qr/Role composition errors/, "batch error header");
    like($@, qr/Field.*\$x.*conflicts/i, "field conflict in batch");
    like($@, qr/Method.*'m'.*conflicts/i, "method conflict in batch");
}

# Field conflict cannot be resolved by consumer method
{
    role FA4 { field $x :param; }
    role FB4 { field $x :param; }

    eval q{
        class FC4 :does(FA4) :does(FB4) {
            method x { "override" }
        }
    };
    like($@, qr/Field.*\$x.*conflicts/i,
         "field conflict is unresolvable even with consumer method");
}

done_testing;
