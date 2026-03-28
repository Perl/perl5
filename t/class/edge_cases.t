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

Edge cases for the class system: unusual but valid constructions,
boundary conditions, and corner cases.

=cut

# Empty class (no fields, no methods)
{
    class EdgeEmpty1 { }

    my $obj = EdgeEmpty1->new;
    isa_ok($obj, "EdgeEmpty1");
    is(ref $obj, "EdgeEmpty1", 'ref of empty class instance');
}

# Class with only fields, no methods
{
    class EdgeFieldsOnly1 {
        field $x = 1;
        field $y = 2;
    }

    my $obj = EdgeFieldsOnly1->new;
    isa_ok($obj, "EdgeFieldsOnly1");
    # Fields exist but we have no methods to inspect them
    pass('Class with only fields can be instantiated');
}

# Class with only methods, no fields
{
    class EdgeMethodsOnly1 {
        method hello { "hello" }
        method world { "world" }
    }

    my $obj = EdgeMethodsOnly1->new;
    is($obj->hello, "hello", 'Method in fieldless class');
    is($obj->world, "world", 'Second method in fieldless class');
}

# Class with only ADJUST, no fields or methods
{
    my $adjusted = 0;
    class EdgeAdjustOnly1 {
        ADJUST { $adjusted = 1 }
    }

    EdgeAdjustOnly1->new;
    is($adjusted, 1, 'ADJUST-only class works');
}

# Deeply nested package name
{
    class A::B::C::D::E {
        field $x :reader = "deep";
    }

    is(A::B::C::D::E->new->x, "deep", 'Deeply nested package name class');
}

# Class with single-character name
{
    class X {
        field $v :reader = "x";
    }

    is(X->new->v, "x", 'Single-character class name');
}

# Method returning $self
{
    class EdgeSelfReturn1 {
        field $x :reader :writer = 0;

        method chain_inc {
            $x++;
            return $self;
        }
    }

    my $obj = EdgeSelfReturn1->new;
    $obj->chain_inc->chain_inc->chain_inc;
    is($obj->x, 3, 'Method chaining via $self return');
}

# Method calling another method on $self
{
    class EdgeSelfCall1 {
        field $x = 10;
        method get_x { $x }
        method doubled { $self->get_x * 2 }
        method describe { "val=" . $self->doubled }
    }

    is(EdgeSelfCall1->new->describe, "val=20",
        'Method calling other methods on $self');
}

# wantarray in methods
{
    class EdgeWantarray1 {
        method context {
            if (wantarray) { return ("list", "context") }
            elsif (defined wantarray) { return "scalar" }
            else { return "void" }
        }
    }

    my $obj = EdgeWantarray1->new;
    my @list = $obj->context;
    ok(eq_array(\@list, ["list", "context"]), 'wantarray list context in method');
    my $scalar = $obj->context;
    is($scalar, "scalar", 'wantarray scalar context in method');
}

# caller() from a method
{
    class EdgeCaller1 {
        method get_caller { return (caller(0))[3] }
    }

    like(EdgeCaller1->new->get_caller, qr/EdgeCaller1::get_caller/,
        'caller() inside method reports correct sub name');
}

# Redefining inherited method with different behavior
{
    class EdgeOverride1 {
        method greet { "base" }
        method describe { "base:" . $self->greet }
    }
    class EdgeOverride2 :isa(EdgeOverride1) {
        method greet { "child" }
    }

    is(EdgeOverride2->new->greet, "child", 'Overridden method');
    is(EdgeOverride2->new->describe, "base:child",
        'Base method calls overridden method via $self');
}

# Virtual dispatch (base method calling overridden method)
{
    class EdgeVirtual1 {
        method type { "base" }
        method label { "I am " . $self->type }
    }
    class EdgeVirtual2 :isa(EdgeVirtual1) {
        method type { "derived" }
    }

    is(EdgeVirtual1->new->label, "I am base", 'Virtual dispatch: base');
    is(EdgeVirtual2->new->label, "I am derived", 'Virtual dispatch: derived');
}

# Multiple instances of same class are independent
{
    class EdgeIndep1 {
        field $n :param :reader :writer;
    }

    my $a = EdgeIndep1->new(n => 1);
    my $b = EdgeIndep1->new(n => 2);
    my $c = EdgeIndep1->new(n => 3);

    $b->set_n(20);
    is($a->n, 1, 'Instance a unaffected');
    is($b->n, 20, 'Instance b modified');
    is($c->n, 3, 'Instance c unaffected');
}

# Field with undef default, then set in ADJUST
{
    class EdgeUndefAdj1 {
        field $x;
        ADJUST { $x = "set-in-adjust" }
        method x { $x }
    }

    is(EdgeUndefAdj1->new->x, "set-in-adjust",
        'Field defaults to undef then set in ADJUST');
}

# ADJUST can access :param fields
{
    class EdgeAdjParam1 {
        field $x :param;
        field $computed;
        ADJUST { $computed = "computed:$x" }
        method computed { $computed }
    }

    is(EdgeAdjParam1->new(x => "hello")->computed, "computed:hello",
        'ADJUST can access :param field');
}

# ADJUST die is catchable and does not corrupt state
{
    class EdgeAdjDie1 {
        field $x :param = "safe";
        method x { $x }
        ADJUST { die "boom\n" if $x eq "bad" }
    }

    my $good = EdgeAdjDie1->new;
    is($good->x, "safe", 'Normal construction OK');

    eval { EdgeAdjDie1->new(x => "bad") };
    is($@, "boom\n", 'ADJUST die is catchable');

    my $after = EdgeAdjDie1->new(x => "after");
    is($after->x, "after", 'Construction works after ADJUST die');
}

# Multiple ADJUST blocks, one dies
{
    my @trace;
    class EdgeMultiAdj1 {
        ADJUST { push @trace, "first" }
        ADJUST { die "second-boom\n" }
        ADJUST { push @trace, "third" }  # should not run
    }

    @trace = ();
    eval { EdgeMultiAdj1->new };
    is($@, "second-boom\n", 'Die in middle ADJUST');
    ok(eq_array(\@trace, ["first"]), 'Only ADJUST blocks before die ran');
}

# eval {} inside a method
{
    class EdgeEvalMethod1 {
        field $x = 42;
        method safe_div ($y) {
            my $result = eval { $x / $y };
            return defined $result ? $result : "error";
        }
    }

    my $obj = EdgeEvalMethod1->new;
    is($obj->safe_div(2), 21, 'eval in method: success');
    is($obj->safe_div(0), "error", 'eval in method: catches error');
}

# die inside a method
{
    class EdgeDieMethod1 {
        method fail { die "method-die\n" }
    }

    eval { EdgeDieMethod1->new->fail };
    is($@, "method-die\n", 'die in method is catchable');
}

# Class with many fields (boundary for field index)
{
    my $code = "class EdgeManyFields1 {\n";
    for my $i (0..99) {
        $code .= "    field \$f$i = $i;\n";
    }
    $code .= "    method sum {\n";
    $code .= "        return " . join(" + ", map { "\$f$_" } 0..99) . ";\n";
    $code .= "    }\n";
    $code .= "}\n";
    $code .= "1;\n";
    eval $code or die $@;

    is(EdgeManyFields1->new->sum, 4950, '100 fields in one class');
}

# Field initialized from previous field
{
    class EdgeFieldChain1 {
        field $a = 1;
        field $b = $a * 10;
        field $c = $b * 10;
        field $d = $c * 10;
        method d { $d }
    }

    is(EdgeFieldChain1->new->d, 1000, 'Chained field initialization');
}

# Field init using complex expression
{
    my $call_count = 0;

    class EdgeComplexInit1 {
        my $counter_ref = \$call_count;
        field $x = do { $$counter_ref++; 21 * 2 };
        method x { $x }
    }

    is(EdgeComplexInit1->new->x, 42, 'Field init with complex expression');
    is($call_count, 1, 'Expression evaluated once per instance');

    EdgeComplexInit1->new;
    is($call_count, 2, 'Expression evaluated again for second instance');
}

# $self is available in ADJUST but not in field init
# ($self in field init is a compile error, tested in t/lib/croak/class)
{
    my $self_in_adjust;
    class EdgeSelfAdjust1 {
        ADJUST { $self_in_adjust = ref $self }
    }

    EdgeSelfAdjust1->new;
    is($self_in_adjust, "EdgeSelfAdjust1", '$self in ADJUST has correct type');
}

# Nested class definitions (class inside class block)
{
    class EdgeOuter1 {
        field $x :reader = "outer";

        class EdgeInner1 {
            field $y :reader = "inner";
        }
    }

    is(EdgeOuter1->new->x, "outer", 'Outer of nested class');
    is(EdgeInner1->new->y, "inner", 'Inner of nested class');
    ok(!EdgeInner1->isa("EdgeOuter1"), 'Nested class does not inherit outer');
}

# Nested class inheriting from outer
{
    class EdgeOuter2 {
        field $x :reader = "from-outer";

        class EdgeInner2 :isa(EdgeOuter2) {
            field $y :reader = "from-inner";
        }
    }

    my $obj = EdgeInner2->new;
    is($obj->x, "from-outer", 'Nested child inherits outer parent field');
    is($obj->y, "from-inner", 'Nested child has own field');
    ok($obj isa EdgeOuter2, 'Nested child isa outer');
}

# Constructor with no params on class with no :param fields
{
    class EdgeNoParam1 {
        field $x = "default";
        method x { $x }
    }

    my $obj = EdgeNoParam1->new;
    is($obj->x, "default", 'Constructor with no params on paramless class');

    # Passing params should fail
    eval { EdgeNoParam1->new(x => 1) };
    like($@, qr/Unrecognized parameters/,
        'Passing params to paramless class fails');
}

# Object identity
{
    class EdgeIdent1 { }

    my $a = EdgeIdent1->new;
    my $b = EdgeIdent1->new;
    ok($a != $b, 'Different instances are not numerically equal');
    my $c = $a;
    ok($a == $c, 'Same instance is numerically equal');
}

# Object as hash key (stringification)
{
    class EdgeHashKey1 {
        field $name :param :reader;
    }

    my $obj = EdgeHashKey1->new(name => "test");
    my %h;
    $h{$obj} = "found";
    is($h{$obj}, "found", 'Object usable as hash key via stringify');
}

done_testing;
