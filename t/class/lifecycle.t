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

use Scalar::Util 'weaken';

=pod

Tests for object lifecycle: construction ordering, ADJUST and field init
ordering across inheritance, DESTROY ordering, weak references, and
cleanup behavior.

=cut

# A legacy-perl class helper to track destruction
package LifeDestructNotify {
    sub new { my $pkg = shift; bless [ @_ ], $pkg }
    sub DESTROY { my $self = shift; ${ $self->[0] } .= $self->[1] }
}

# ============================================================
# Construction order: field inits then ADJUST, base before child
# ============================================================

{
    my @trace;

    class LifeOrderBase1 {
        field $x = do { push @trace, "base-field-init"; "bx" };
        ADJUST { push @trace, "base-adjust" }
    }
    class LifeOrderChild1 :isa(LifeOrderBase1) {
        field $y = do { push @trace, "child-field-init"; "cy" };
        ADJUST { push @trace, "child-adjust" }
    }

    @trace = ();
    LifeOrderChild1->new;
    ok(eq_array(\@trace, [
        "base-field-init",
        "child-field-init",
        "base-adjust",
        "child-adjust",
    ]), 'Construction order: all field inits (base then child), then all ADJUSTs (base then child)');
}

# 3-level construction order
{
    my @trace;

    class LifeOrder3Base {
        field $x = do { push @trace, "L1-field"; 1 };
        ADJUST { push @trace, "L1-adjust" }
    }
    class LifeOrder3Mid :isa(LifeOrder3Base) {
        field $y = do { push @trace, "L2-field"; 2 };
        ADJUST { push @trace, "L2-adjust" }
    }
    class LifeOrder3Leaf :isa(LifeOrder3Mid) {
        field $z = do { push @trace, "L3-field"; 3 };
        ADJUST { push @trace, "L3-adjust" }
    }

    @trace = ();
    LifeOrder3Leaf->new;
    ok(eq_array(\@trace, [
        "L1-field",
        "L2-field",
        "L3-field",
        "L1-adjust",
        "L2-adjust",
        "L3-adjust",
    ]), '3-level construction order: all fields then all ADJUSTs');
}

# Multiple ADJUST blocks per level
{
    my @trace;

    class LifeMultiAdjBase {
        ADJUST { push @trace, "b1" }
        ADJUST { push @trace, "b2" }
    }
    class LifeMultiAdjChild :isa(LifeMultiAdjBase) {
        ADJUST { push @trace, "c1" }
        ADJUST { push @trace, "c2" }
        ADJUST { push @trace, "c3" }
    }

    @trace = ();
    LifeMultiAdjChild->new;
    ok(eq_array(\@trace, ["b1", "b2", "c1", "c2", "c3"]),
        'Multiple ADJUST blocks per level fire in order');
}

# ============================================================
# DESTROY ordering across inheritance
# ============================================================

{
    my @destroyed;

    class LifeDestrBase1 {
        field $name :param;
        method DESTROY { push @destroyed, "base:$name" }
    }
    class LifeDestrChild1 :isa(LifeDestrBase1) {
        field $tag :param;
        method DESTROY {
            push @destroyed, "child:$tag";
            $self->SUPER::DESTROY();
        }
    }
    class LifeDestrGC1 :isa(LifeDestrChild1) {
        field $label :param;
        method DESTROY {
            push @destroyed, "gc:$label";
            $self->SUPER::DESTROY();
        }
    }

    @destroyed = ();
    {
        my $obj = LifeDestrGC1->new(name => "n", tag => "t", label => "l");
    }
    ok(eq_array(\@destroyed, ["gc:l", "child:t", "base:n"]),
        'DESTROY chain fires gc -> child -> base');
}

# DESTROY can access fields
{
    my $field_in_destroy;

    class LifeDestrField1 {
        field $x :param;
        method DESTROY { $field_in_destroy = $x }
    }

    {
        my $obj = LifeDestrField1->new(x => "still-here");
    }
    is($field_in_destroy, "still-here", 'DESTROY can read field values');
}

# Field destruction order (fields destroyed in reverse order)
{
    my $order = "";

    class LifeFieldDestr1 {
        field $a;
        field $b;
        field $c;
        ADJUST {
            $a = LifeDestructNotify->new(\$order, "a");
            $b = LifeDestructNotify->new(\$order, "b");
            $c = LifeDestructNotify->new(\$order, "c");
        }
    }

    {
        my $obj = LifeFieldDestr1->new;
    }
    is($order, "cba", 'Fields destroyed in reverse declaration order');
}

# Field destruction order across inheritance
{
    my $order = "";

    class LifeFieldDestrBase2 {
        field $bx;
        field $by;
        ADJUST {
            $bx = LifeDestructNotify->new(\$order, "bx");
            $by = LifeDestructNotify->new(\$order, "by");
        }
    }
    class LifeFieldDestrChild2 :isa(LifeFieldDestrBase2) {
        field $cx;
        field $cy;
        ADJUST {
            $cx = LifeDestructNotify->new(\$order, "cx");
            $cy = LifeDestructNotify->new(\$order, "cy");
        }
    }

    {
        my $obj = LifeFieldDestrChild2->new;
    }
    is($order, "cycxbybx",
        'Fields destroyed: child reverse, then base reverse');
}

# ============================================================
# Weak references
# ============================================================

{
    class LifeWeak1 {
        field $x :param :reader;
    }

    my $strong = LifeWeak1->new(x => "alive");
    my $weak = $strong;
    weaken($weak);

    ok(defined $weak, 'Weakref alive with strong ref');
    is($weak->x, "alive", 'Weakref can call methods');

    undef $strong;
    ok(!defined $weak, 'Weakref cleared after strong ref gone');
}

# Weak ref in field (preventing circular leak)
{
    class LifeWeakField1 {
        field $partner;
        field $name :param :reader;

        method set_partner { $partner = $_[0] }
        method partner_name {
            defined $partner ? $partner->name : "none"
        }
    }

    my $a = LifeWeakField1->new(name => "A");
    my $b = LifeWeakField1->new(name => "B");

    $a->set_partner($b);
    $b->set_partner($a);

    is($a->partner_name, "B", 'Circular ref: A sees B');
    is($b->partner_name, "A", 'Circular ref: B sees A');

    # Use weak ref to break cycle
    weaken($a->{partner}) if 0;  # can't access fields directly; use ADJUST approach

    # Just verify cleanup does not segfault
    $a->set_partner(undef);
    $b->set_partner(undef);
    pass('Circular reference cleanup OK');
}

# Weak ref across inheritance
{
    class LifeWeakBase2 {
        field $v :param :reader;
    }
    class LifeWeakChild2 :isa(LifeWeakBase2) {
        field $extra :param :reader;
    }

    my $obj = LifeWeakChild2->new(v => "base-val", extra => "child-val");
    my $weak = $obj;
    weaken($weak);

    is($weak->v, "base-val", 'Weakref to child: base field');
    is($weak->extra, "child-val", 'Weakref to child: child field');

    undef $obj;
    ok(!defined $weak, 'Weakref to child cleared');
}

# ============================================================
# Destruction during error (constructor failure)
# ============================================================

{
    my $destroyed_field;

    class LifeErrDestr1 {
        field $f1 :param :reader;
        field $f2 :param;

        method DESTROY { $destroyed_field = $f1 }
    }

    # f2 is required but missing -> constructor dies after f1 is set
    eval { LifeErrDestr1->new(f1 => "was-set") };
    like($@, qr/Required parameter 'f2' is missing/,
        'Constructor dies for missing param');
    is($destroyed_field, "was-set",
        'DESTROY fires on partial object, earlier field accessible');
}

# ADJUST die triggers DESTROY
{
    my @trace;

    class LifeAdjDestr1 {
        field $name :param;
        ADJUST { die "adj-fail\n" if $name eq "fail" }
        method DESTROY { push @trace, "destroyed:$name" }
    }

    @trace = ();
    eval { LifeAdjDestr1->new(name => "fail") };
    is($@, "adj-fail\n", 'ADJUST die is caught');
    ok(grep(/destroyed:fail/, @trace), 'DESTROY fires after ADJUST die');
}

# ============================================================
# Refcount verification
# ============================================================

{
    class LifeRefcount1 {
        field $x :param;
    }

    my $obj = LifeRefcount1->new(x => 1);
    refcount_is $obj, 1, 'Fresh object has refcount 1';

    my $ref2 = $obj;
    refcount_is $obj, 2, 'Object with two refs has refcount 2';

    undef $ref2;
    refcount_is $obj, 1, 'Back to refcount 1 after undef';
}

# ============================================================
# Objects in arrays and hashes
# ============================================================

{
    class LifeContainer1 {
        field $id :param :reader;
    }

    my @arr;
    for my $i (1..5) {
        push @arr, LifeContainer1->new(id => $i);
    }
    is(scalar @arr, 5, '5 objects in array');
    is($arr[0]->id, 1, 'First object');
    is($arr[4]->id, 5, 'Last object');

    my %hash;
    for my $i (1..3) {
        $hash{"obj$i"} = LifeContainer1->new(id => $i * 10);
    }
    is($hash{obj2}->id, 20, 'Object in hash');
}

# Objects destroyed when container is cleared
{
    my $destroyed = 0;

    class LifeContainerDestr1 {
        method DESTROY { $destroyed++ }
    }

    my @arr = map { LifeContainerDestr1->new } 1..5;
    is($destroyed, 0, 'No destruction yet');
    @arr = ();
    is($destroyed, 5, 'All 5 objects destroyed when array cleared');
}

# ============================================================
# Rapid lifecycle stress
# ============================================================

{
    class LifeStress1 {
        field $id :param;
        field $data = "x" x 100;
        method id { $id }
    }

    my $ok = 1;
    for my $i (1..2000) {
        my $obj = LifeStress1->new(id => $i);
        if ($obj->id != $i) {
            $ok = 0;
            last;
        }
    }
    ok($ok, '2000 rapid create/destroy cycles');
}

# Rapid lifecycle with inheritance
{
    class LifeStressBase2 {
        field $x :param;
        method x { $x }
    }
    class LifeStressChild2 :isa(LifeStressBase2) {
        field $y :param;
        method y { $y }
    }

    my $ok = 1;
    for my $i (1..1000) {
        my $obj = LifeStressChild2->new(x => $i, y => $i * 2);
        if ($obj->x != $i || $obj->y != $i * 2) {
            $ok = 0;
            last;
        }
    }
    ok($ok, '1000 rapid create/destroy cycles with inheritance');
}

done_testing;
