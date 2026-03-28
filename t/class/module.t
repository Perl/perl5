#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.36;
use feature 'class';
no warnings 'experimental::class';

=pod

Tests for class interaction with the module/require system.

=cut

# Class in a require'd file (already tested for :isa auto-loading in inherit.t,
# but here we test broader module integration)
{
    use lib 'lib/class';
    ok(eval { require A::B; 1 }, 'can require a class module')
        or diag("Error: $@");
    my $obj = A::B->new;
    isa_ok($obj, "A::B", 'required class module creates objects');
}

# Multiple classes defined in a single eval (simulating one file)
{
    eval q{
        class ModMulti1 {
            field $x :reader = "one";
        }
        class ModMulti2 {
            field $y :reader = "two";
        }
        1;
    } or die $@;

    is(ModMulti1->new->x, "one", 'First class from multi-class eval');
    is(ModMulti2->new->y, "two", 'Second class from multi-class eval');
}

# Class with regular subs alongside methods
{
    class ModMixed1 {
        my $counter = 0;

        sub class_method { return "class_method" }
        sub increment { $counter++ }
        sub get_count { $counter }

        field $x :param :reader;

        method describe { "ModMixed1($x)" }
    }

    is(ModMixed1::class_method(), "class_method",
        'Regular sub in class is callable');
    ModMixed1::increment();
    ModMixed1::increment();
    is(ModMixed1::get_count(), 2, 'Regular sub shares class lexicals');

    my $obj = ModMixed1->new(x => "test");
    is($obj->describe, "ModMixed1(test)", 'Method works alongside subs');
}

# Class with use constant
{
    class ModConst1 {
        use constant PI => 3.14159;
        use constant NAME => "ModConst1";

        field $radius :param :reader;
        method area { PI * $radius * $radius }
    }

    is(ModConst1::PI, 3.14159, 'use constant in class');
    is(ModConst1::NAME, "ModConst1", 'use constant for name in class');
    my $obj = ModConst1->new(radius => 10);
    # Just check it computes without dying
    ok($obj->area > 314 && $obj->area < 315, 'method using constant works');
}

# Class with use overload
{
    class ModOverload1 {
        field $value :param :reader;

        use overload
            '""' => sub { "ModOverload1(" . $_[0]->value . ")" },
            '0+' => sub { $_[0]->value },
            '==' => sub { $_[0]->value == (ref $_[1] ? $_[1]->value : $_[1]) },
            fallback => 1;
    }

    my $obj = ModOverload1->new(value => 42);
    is("$obj", "ModOverload1(42)", 'overloaded stringify');
    is($obj + 0, 42, 'overloaded numify');
    ok($obj == 42, 'overloaded == with scalar');

    my $obj2 = ModOverload1->new(value => 42);
    ok($obj == $obj2, 'overloaded == with another object');
}

# Class package variables coexist with fields
{
    class ModPkgVar1 {
        our $CLASS_VAR = "shared";
        our @CLASS_LIST = (1, 2, 3);
        our %CLASS_MAP = (a => 1);

        field $instance :param :reader;

        method combined { "$CLASS_VAR:$instance" }
    }

    is($ModPkgVar1::CLASS_VAR, "shared", 'our variable in class');
    ok(eq_array(\@ModPkgVar1::CLASS_LIST, [1, 2, 3]), 'our array in class');
    ok(eq_hash(\%ModPkgVar1::CLASS_MAP, {a => 1}), 'our hash in class');

    my $obj = ModPkgVar1->new(instance => "inst");
    is($obj->combined, "shared:inst", 'method accesses both our and field');
}

# Class in eval across separate compilation units with use
fresh_perl_is(<<'CODE', "hello 42\n", {}, 'Class defined in eval, used in another eval');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
eval q{
    class EvalMod1 {
        field $msg :param;
        field $num :param;
        method describe { "$msg $num" }
    }
    1;
} or die $@;
eval q{
    print EvalMod1->new(msg => "hello", num => 42)->describe, "\n";
    1;
} or die $@;
CODE

# Class in BEGIN block is available at runtime
fresh_perl_is(<<'CODE', "works\n", {}, 'Class in BEGIN is available at runtime');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
BEGIN {
    eval q{
        class BeginMod1 {
            field $x :reader = "works";
        }
        1;
    } or die $@;
}
print BeginMod1->new->x, "\n";
CODE

# Nested classes in same package hierarchy
{
    class ModNest1 {
        field $x :reader = "outer";
    }
    class ModNest1::Inner {
        field $y :reader = "inner";
    }
    class ModNest1::Inner::Deep {
        field $z :reader = "deep";
    }

    is(ModNest1->new->x, "outer", 'Outer class of nested hierarchy');
    is(ModNest1::Inner->new->y, "inner", 'Inner class of nested hierarchy');
    is(ModNest1::Inner::Deep->new->z, "deep", 'Deeply nested class');
}

# Class with Exporter-like functionality via regular subs
{
    class ModExportLike1 {
        my @exports;

        sub import {
            my ($class, @syms) = @_;
            # Just verify import is called
            push @exports, @syms;
        }

        sub exported { return \@exports }

        field $x :reader = "instance";
    }

    # Simulate what 'use' would do
    ModExportLike1->import("foo", "bar");
    ok(eq_array(ModExportLike1::exported(), ["foo", "bar"]),
        'import sub in class works');

    my $obj = ModExportLike1->new;
    is($obj->x, "instance", 'class still works as a class after import');
}

# AUTOLOAD does not interfere with class methods
{
    class ModAutoload1 {
        field $x :reader = "real";

        sub AUTOLOAD {
            our $AUTOLOAD;
            return "auto:$AUTOLOAD";
        }
    }

    my $obj = ModAutoload1->new;
    is($obj->x, "real", 'Real method called, not AUTOLOAD');
    is($obj->nonexistent, "auto:ModAutoload1::nonexistent",
        'AUTOLOAD works for missing methods');
}

# isa() and DOES() on class instances
{
    class ModIsa1 { }
    class ModIsa2 :isa(ModIsa1) { }

    my $obj = ModIsa2->new;
    ok($obj->isa("ModIsa2"), '$obj->isa own class');
    ok($obj->isa("ModIsa1"), '$obj->isa parent class');
    ok($obj->isa("UNIVERSAL"), '$obj->isa UNIVERSAL (all objects do)');

    ok($obj->DOES("ModIsa2"), '$obj->DOES own class');
    ok($obj->DOES("ModIsa1"), '$obj->DOES parent class');

    ok($obj->can("new"), '$obj->can("new")');
    ok(!$obj->can("nonexistent_method_xyz"), '$obj->can returns false for missing');
}

# Class interacting with regular Perl BEGIN/END blocks
fresh_perl_is(<<'CODE', "begin adjust\n", {}, 'BEGIN and ADJUST blocks coexist in class');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
my @order;
class ModPhase1 {
    BEGIN { push @order, "begin" }
    ADJUST { push @order, "adjust" }
}
ModPhase1->new;
print join(" ", @order), "\n";
CODE

done_testing;
