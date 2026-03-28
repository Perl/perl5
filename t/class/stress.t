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

Stress tests for the Perl class system, focusing on:
- Seal ordering with unit-syntax and block-syntax classes
- Field index correctness across inheritance chains
- Pathological combinations of fields, :param, :reader, :writer, ADJUST
- Edge cases that have historically caused segfaults (GH#20890, GH#21221)

These tests use fresh_perl_is/fresh_perl_like where a segfault is plausible,
so a crash doesn't take down the test harness.

=cut

# ============================================================
# GH#20890 / GH#21221: seal ordering with unit-syntax classes
# ============================================================

# GH#21221: empty base class, both unit syntax
fresh_perl_is(<<'CODE', "ok\n", {}, 'Empty unit-syntax base and child (GH#21221)');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{ class Animal; class Dog :isa(Animal); }
print "ok\n";
CODE

# GH#20890: unit-syntax base with fields, unit-syntax child
fresh_perl_is(<<'CODE', "42\n", {}, 'Unit-syntax base with field, unit-syntax child inherits');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class UBase;
    field $x = 42;
    method x { return $x }
    class UChild :isa(UBase);
}
print UChild->new->x, "\n";
CODE

# Block-scoped subclass defined inside base class body
fresh_perl_is(<<'CODE', "10 20\n", {}, 'Block-scoped child inside base class body');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
class Outer {
    field $x = 10;
    method x { $x }
    class Inner :isa(Outer) {
        field $y = 20;
        method y { $y }
    }
}
my $obj = Inner->new;
print $obj->x, " ", $obj->y, "\n";
CODE

# Multiple subclasses of the same unsealed base
fresh_perl_is(<<'CODE', "b b b\n", {}, 'Multiple subclasses of same unit-syntax base');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class MBase;
    field $v = "b";
    method v { $v }
    class MSub1 :isa(MBase);
    class MSub2 :isa(MBase);
    class MSub3 :isa(MBase);
}
print MSub1->new->v, " ", MSub2->new->v, " ", MSub3->new->v, "\n";
CODE

# Mixed unit/block syntax with shared base
fresh_perl_is(<<'CODE', "a b a c\n", {}, 'Mixed unit/block siblings sharing unit-syntax base');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class MixBase;
    field $a = "a";
    method a { $a }

    class MixBlock :isa(MixBase) {
        field $b = "b";
        method b { $b }
    }

    class MixUnit :isa(MixBase);
    field $c = "c";
    method c { $c }
}
print MixBlock->new->a, " ", MixBlock->new->b, " ",
      MixUnit->new->a, " ", MixUnit->new->c, "\n";
CODE

# Alternating unit/block syntax in a chain
fresh_perl_is(<<'CODE', "u b u\n", {}, 'Alternating unit/block/unit inheritance chain');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class AltBase;
    field $u1 = "u";
    method u1 { $u1 }

    class AltBlock :isa(AltBase) {
        field $b = "b";
        method b { $b }
    }

    class AltUnit :isa(AltBlock);
    field $u2 = "u";
    method u2 { $u2 }
}
my $obj = AltUnit->new;
print $obj->u1, " ", $obj->b, " ", $obj->u2, "\n";
CODE

# ============================================================
# Deep inheritance chains (stress field index computation)
# ============================================================

# 5-level deep unit-syntax chain
fresh_perl_is(<<'CODE', "12345\n", {}, '5-level deep unit-syntax inheritance chain');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class D1; field $f1 = 1; method f1 { $f1 }
    class D2 :isa(D1); field $f2 = 2; method f2 { $f2 }
    class D3 :isa(D2); field $f3 = 3; method f3 { $f3 }
    class D4 :isa(D3); field $f4 = 4; method f4 { $f4 }
    class D5 :isa(D4); field $f5 = 5; method f5 { $f5 }
}
my $obj = D5->new;
print $obj->f1, $obj->f2, $obj->f3, $obj->f4, $obj->f5, "\n";
CODE

# 4-level nested block classes, each inheriting from parent
fresh_perl_is(<<'CODE', "1234\n", {}, 'Deeply nested block classes inheriting from outer');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
class N1 {
    field $n1 = 1; method n1 { $n1 }
    class N2 :isa(N1) {
        field $n2 = 2; method n2 { $n2 }
        class N3 :isa(N2) {
            field $n3 = 3; method n3 { $n3 }
            class N4 :isa(N3) {
                field $n4 = 4; method n4 { $n4 }
            }
        }
    }
}
my $obj = N4->new;
print $obj->n1, $obj->n2, $obj->n3, $obj->n4, "\n";
CODE

# Tree-shaped inheritance (not just linear chain)
fresh_perl_is(<<'CODE', "abd ace\n", {}, 'Tree-shaped inheritance with unit syntax');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class TA; field $a = "a"; method a { $a }
    class TB :isa(TA); field $b = "b"; method b { $b }
    class TC :isa(TA); field $c = "c"; method c { $c }
    class TD :isa(TB); field $d = "d"; method d { $d }
    class TE :isa(TC); field $e = "e"; method e { $e }
}
my $d = TD->new;
my $e = TE->new;
print $d->a, $d->b, $d->d, " ", $e->a, $e->c, $e->e, "\n";
CODE

# Chain of empty (field-less) classes
fresh_perl_is(<<'CODE', "EmptyC yes\n", {}, 'Chain of empty unit-syntax classes');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class EmptyA;
    class EmptyB :isa(EmptyA);
    class EmptyC :isa(EmptyB);
}
my $obj = EmptyC->new;
print ref($obj), " ", ($obj isa EmptyA ? "yes" : "no"), "\n";
CODE

# Interleaved empty/non-empty classes
fresh_perl_is(<<'CODE', "hello world\n", {}, 'Interleaved empty and field-bearing classes in chain');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class IE_NoField;
    class IE_HasField :isa(IE_NoField);
    field $x :param;
    method x { $x }
    class IE_NoField2 :isa(IE_HasField);
    class IE_HasField2 :isa(IE_NoField2);
    field $y :param;
    method y { $y }
}
my $obj = IE_HasField2->new(x => "hello", y => "world");
print $obj->x, " ", $obj->y, "\n";
CODE

# ============================================================
# Field index correctness
# ============================================================

# Many fields in base, few in child
{
    class BigBase {
        field $f0 = 0; field $f1 = 1; field $f2 = 2; field $f3 = 3;
        field $f4 = 4; field $f5 = 5; field $f6 = 6; field $f7 = 7;
        field $f8 = 8; field $f9 = 9;
        method sum { $f0+$f1+$f2+$f3+$f4+$f5+$f6+$f7+$f8+$f9 }
        method last_base { $f9 }
    }
    class BigChild :isa(BigBase) {
        field $g0 = 10; field $g1 = 11;
        method child_sum { $g0 + $g1 }
        method last_base { $g1 }  # override
    }

    my $obj = BigChild->new;
    is($obj->sum, 45, 'Field sum from base with 10 fields');
    is($obj->child_sum, 21, 'Field sum from child with 2 fields');
    is($obj->last_base, 11, 'Method override returns child field');
}

# Same-named fields in parent and child (field shadowing)
{
    class ShadowBase {
        field $x = "base-x";
        field $y = "base-y";
        method base_x { $x }
        method base_y { $y }
    }
    class ShadowChild :isa(ShadowBase) {
        field $x = "child-x";
        field $y = "child-y";
        method child_x { $x }
        method child_y { $y }
    }

    my $obj = ShadowChild->new;
    is($obj->base_x, "base-x", 'Parent method sees parent field $x');
    is($obj->base_y, "base-y", 'Parent method sees parent field $y');
    is($obj->child_x, "child-x", 'Child method sees child field $x');
    is($obj->child_y, "child-y", 'Child method sees child field $y');
}

# Fieldless children of field-heavy base
{
    class FieldyBase {
        field $a :param = "da";
        field $b :param = "db";
        field $c :param = "dc";
        method abc { "$a-$b-$c" }
    }
    class EmptyChild1 :isa(FieldyBase) {}
    class EmptyGC1 :isa(EmptyChild1) {}

    my $obj = EmptyGC1->new(a => "A", b => "B", c => "C");
    is($obj->abc, "A-B-C", 'Fieldless children pass params through to base');
}

# Large field count via eval (50 fields)
fresh_perl_is(<<'CODE', "1225 999\n", {}, '50 fields in base, child adds one more');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
my $fields = join "\n", map { "field \$f$_ = $_;" } 0..49;
my $sum = join " + ", map { "\$f$_" } 0..49;
eval qq{
    class Big50 { $fields method sum { $sum } }
    class Big50Child :isa(Big50) {
        field \$extra = 999;
        method extra { \$extra }
    }
    1;
} or die $@;
my $obj = Big50Child->new;
print $obj->sum, " ", $obj->extra, "\n";
CODE

# ============================================================
# :param, :reader, :writer across inheritance
# ============================================================

# :param across unit-syntax inheritance chain
{
    class ParamChainBase {
        field $name :param;
        method name { $name }
    }
    class ParamChainMid :isa(ParamChainBase) {
        field $age :param;
        method age { $age }
    }
    class ParamChainLeaf :isa(ParamChainMid) {
        field $color :param;
        method color { $color }
    }

    my $obj = ParamChainLeaf->new(name => "A", age => 1, color => "red");
    is($obj->name, "A", ':param works through 3-level chain (base)');
    is($obj->age, 1, ':param works through 3-level chain (mid)');
    is($obj->color, "red", ':param works through 3-level chain (leaf)');
}

# :reader across inheritance
{
    class ReaderBase {
        field $rb :reader = "base-read";
    }
    class ReaderChild :isa(ReaderBase) {
        field $rc :reader = "child-read";
    }

    my $obj = ReaderChild->new;
    is($obj->rb, "base-read", ':reader on base field works in child');
    is($obj->rc, "child-read", ':reader on child field works');
}

# :writer across inheritance
{
    class WriterBase {
        field $wb :reader :writer = "wb-init";
    }
    class WriterChild :isa(WriterBase) {
        field $wc :reader :writer = "wc-init";
    }

    my $obj = WriterChild->new;
    $obj->set_wb("wb-new");
    $obj->set_wc("wc-new");
    is($obj->wb, "wb-new", ':writer on base field works in child');
    is($obj->wc, "wc-new", ':writer on child field works');
}

# Duplicate :param name across inheritance is an error
{
    ok(!eval q{
        class DupParamBase2 {
            field $x :param;
        }
        class DupParamChild2 :isa(DupParamBase2) {
            field $x :param;
        }
        1;
    }, 'Duplicate :param name across inheritance is an error');
    like($@, qr/already in use/, 'Error message mentions name conflict');
}

# ============================================================
# ADJUST blocks across inheritance
# ============================================================

{
    my @trace;
    class AdjustChainBase {
        field $x;
        ADJUST { $x = 1; push @trace, "b1" }
        ADJUST { push @trace, "b2" }
        method x { $x }
    }
    class AdjustChainChild :isa(AdjustChainBase) {
        field $y;
        ADJUST { $y = 2; push @trace, "c1" }
        ADJUST { push @trace, "c2" }
        method y { $y }
    }
    class AdjustChainGC :isa(AdjustChainChild) {
        ADJUST { push @trace, "gc1" }
    }

    my $obj = AdjustChainGC->new;
    is($obj->x, 1, 'ADJUST sets field in base');
    is($obj->y, 2, 'ADJUST sets field in child');
    is(join(",", @trace), "b1,b2,c1,c2,gc1",
        'ADJUST blocks fire in correct order through chain');
}

# ADJUST-only subclass (no fields)
{
    my @log;
    class AdjOnlyBase2 {
        field $v = "adj-base";
        ADJUST { push @log, "base" }
        method v { $v }
    }
    class AdjOnlyChild2 :isa(AdjOnlyBase2) {
        ADJUST { push @log, "child" }
    }

    my $obj = AdjOnlyChild2->new;
    is($obj->v, "adj-base", 'ADJUST-only child inherits base fields');
    is(join(",", @log), "base,child", 'ADJUST-only child fires ADJUSTs in order');
}

# ============================================================
# __CLASS__ across inheritance
# ============================================================

{
    class ClassTokenBase2 {
        field $class_at_init = __CLASS__;
        method class_at_init { $class_at_init }
    }
    class ClassTokenChild2 :isa(ClassTokenBase2) {
        field $child_class = __CLASS__;
        method child_class { $child_class }
    }

    my $obj = ClassTokenChild2->new;
    is($obj->class_at_init, "ClassTokenChild2",
        '__CLASS__ in base field init yields runtime class');
    is($obj->child_class, "ClassTokenChild2",
        '__CLASS__ in child field init yields runtime class');
}

# ============================================================
# SUPER::method with fields
# ============================================================

{
    class SuperBase2 {
        field $x = "base";
        method describe { "base:$x" }
    }
    class SuperChild2 :isa(SuperBase2) {
        field $y = "child";
        method describe { $self->SUPER::describe() . "/child:$y" }
    }
    class SuperGC2 :isa(SuperChild2) {
        field $z = "gc";
        method describe { $self->SUPER::describe() . "/gc:$z" }
    }

    is(SuperGC2->new->describe, "base:base/child:child/gc:gc",
        'SUPER::method chain with fields at each level');
}

# ============================================================
# Forward-declared methods with fields in inheritance
# ============================================================

{
    class FwdBase {
        field $x = "fwd-base";
        method x;
        method x { $x }
    }
    class FwdChild :isa(FwdBase) {
        field $y = "fwd-child";
        method y;
        method y { $y }
    }

    my $obj = FwdChild->new;
    is($obj->x, "fwd-base", 'Forward-declared method in base works');
    is($obj->y, "fwd-child", 'Forward-declared method in child works');
}

# ============================================================
# Anonymous method closures over fields in inheritance
# ============================================================

{
    class AnonBase2 {
        field $x = 10;
        method get_x_closure {
            return method { $x }
        }
    }
    class AnonChild2 :isa(AnonBase2) {
        field $y = 20;
        method get_y_closure {
            return method { $y }
        }
    }

    my $obj = AnonChild2->new;
    my $xc = $obj->get_x_closure;
    my $yc = $obj->get_y_closure;
    is($obj->$xc, 10, 'Anonymous method closure over base field works');
    is($obj->$yc, 20, 'Anonymous method closure over child field works');
}

# ============================================================
# Closures capturing fields across inheritance
# ============================================================

{
    class ClosureBase2 {
        field $counter = 0;
        method make_callbacks {
            my @callbacks;
            for my $i (1..3) {
                push @callbacks, sub { $counter += $i; return $counter };
            }
            return @callbacks;
        }
        method counter { $counter }
    }
    class ClosureChild2 :isa(ClosureBase2) {
        field $extra = 100;
        method extra { $extra }
    }

    my $obj = ClosureChild2->new;
    my @cbs = $obj->make_callbacks;
    $cbs[0]->();
    $cbs[1]->();
    $cbs[2]->();
    is($obj->counter, 6, 'Closures capturing base field work in child instance');
    is($obj->extra, 100, 'Child field unaffected by base closures');
}

# ============================================================
# Lexical methods with fields in inheritance
# ============================================================

{
    class LexBase2 {
        field $x = "lex-base";
        my method secret { $x }
        method reveal { $self->&secret }
    }
    class LexChild2 :isa(LexBase2) {
        field $y = "lex-child";
        my method child_secret { $y }
        method child_reveal { $self->&child_secret }
    }

    my $obj = LexChild2->new;
    is($obj->reveal, "lex-base", 'Lexical method accessing base field via ->&');
    is($obj->child_reveal, "lex-child", 'Lexical method accessing child field via ->&');
}

# ============================================================
# DESTROY with fields across inheritance
# ============================================================

{
    my @destroyed;
    class DestrBase2 {
        field $name :param;
        method DESTROY { push @destroyed, "base:$name" }
    }
    class DestrChild2 :isa(DestrBase2) {
        field $extra :param;
        method DESTROY { push @destroyed, "child:$extra"; $self->SUPER::DESTROY() }
    }

    {
        my $obj = DestrChild2->new(name => "obj1", extra => "x1");
    }
    is(join(",", @destroyed), "child:x1,base:obj1",
        'DESTROY chain fires correctly with fields from both classes');
}

# ============================================================
# Cross-class method safety
# ============================================================

{
    class SafetyA {
        field $x = "A";
        method x { $x }
    }
    class SafetyB {
        field $y = "B";
        method y { $y }
    }

    my $a = SafetyA->new;
    eval { $a->SafetyB::y() };
    like($@, qr/Cannot invoke a method of "SafetyB" on an instance of "SafetyA"/,
        'Cross-class method invocation gives clear error, not segfault');
}

# ============================================================
# Kitchen sink: all features combined with unit syntax
# ============================================================

fresh_perl_is(<<'CODE', "b-default A-adj e-default 42 KSLeaf-adjusted\nnew-e\n", {}, 'Kitchen sink: all features in unit-syntax chain');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class KSBase;
    field $a :param;
    field $b :reader = "b-default";
    field $c;
    ADJUST { $c = $a . "-adj" }
    method c { $c }

    class KSMid :isa(KSBase);
    field $d :param;
    field $e :reader :writer = "e-default";
    field $f = 42;
    method f { $f }

    class KSLeaf :isa(KSMid);
    field $g :param(gee);
    field $h = __CLASS__;
    ADJUST { $h .= "-adjusted" }
    method h { $h }
}
my $obj = KSLeaf->new(a => "A", d => "D", gee => "G");
print join(" ", $obj->b, $obj->c, $obj->e, $obj->f, $obj->h), "\n";
$obj->set_e("new-e");
print $obj->e, "\n";
CODE

# ============================================================
# Eval-based inheritance (separate compilation units)
# ============================================================

fresh_perl_is(<<'CODE', "1 2 3\n", {}, 'Multi-level inheritance across separate eval compilation units');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
eval q{
    class EvalBase { field $eb :param; method eb { $eb } } 1;
} or die $@;
eval q{
    class EvalMid :isa(EvalBase) { field $em :param; method em { $em } } 1;
} or die $@;
eval q{
    class EvalLeaf :isa(EvalMid) { field $el :param; method el { $el } } 1;
} or die $@;
my $obj = EvalLeaf->new(eb => 1, em => 2, el => 3);
print $obj->eb, " ", $obj->em, " ", $obj->el, "\n";
CODE

# ============================================================
# BEGIN block class definition + runtime subclass
# ============================================================

fresh_perl_is(<<'CODE', "begin runtime\n", {}, 'Class defined in BEGIN block, subclassed at runtime');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
BEGIN {
    eval q{
        class BeginBase2 { field $x = "begin"; method x { $x } } 1;
    } or die $@;
}
class BeginChild2 :isa(BeginBase2) {
    field $y = "runtime";
    method y { $y }
}
my $obj = BeginChild2->new;
print $obj->x, " ", $obj->y, "\n";
CODE

# ============================================================
# Field init order with unit-syntax inheritance
# ============================================================

{
    class InitOrderBase2 {
        field $x = 10;
        field $y = $x * 2;
        method vals { "$x:$y" }
    }
    class InitOrderChild2 :isa(InitOrderBase2) {
        field $z = 30;
        field $w = $z + 1;
        method child_vals { "$z:$w" }
    }

    my $obj = InitOrderChild2->new;
    is($obj->vals, "10:20", 'Base field init order preserved');
    is($obj->child_vals, "30:31", 'Child field init order preserved');
}

# ============================================================
# Rapid object creation/destruction stress test
# ============================================================

{
    class StressBase2 {
        field $x :param;
        field $y = "default";
        method x { $x }
    }
    class StressChild2 :isa(StressBase2) {
        field $z :param = 0;
        method z { $z }
    }

    my $ok = 1;
    for (1..1000) {
        my $obj = StressChild2->new(x => $_, z => $_ * 2);
        if ($obj->x != $_ || $obj->z != $_ * 2) {
            $ok = 0;
            last;
        }
    }
    ok($ok, '1000 rapid object create/destroy cycles with inheritance');
}

# ============================================================
# Class defined inside method (eval at runtime)
# ============================================================

fresh_perl_is(<<'CODE', "10 20\n", {}, 'Class defined inside method via eval');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
class EvalNestBase {
    field $x :param;
    method x { $x }
    method make_child_class {
        eval q{
            class EvalNestChild :isa(EvalNestBase) {
                field $y :param;
                method y { $y }
            }
            1;
        } or die $@;
    }
}
EvalNestBase->new(x => 1)->make_child_class;
my $child = EvalNestChild->new(x => 10, y => 20);
print $child->x, " ", $child->y, "\n";
CODE

# ============================================================
# Method override with field access (no SUPER)
# ============================================================

{
    class OverrideBase {
        field $x = "base";
        method x { $x }
    }
    class OverrideChild :isa(OverrideBase) {
        field $y = "child";
        method x { $y }  # override, using own field
    }

    is(OverrideChild->new->x, "child",
        'Method override accessing own field (not base field)');
}

# ============================================================
# SUPER with no own fields
# ============================================================

{
    class SUPERNoFieldBase {
        field $a = 1; field $b = 2; field $c = 3;
        method all { "$a-$b-$c" }
    }
    class SUPERNoFieldChild :isa(SUPERNoFieldBase) {
        method all { "child:" . $self->SUPER::all() }
    }

    is(SUPERNoFieldChild->new->all, "child:1-2-3",
        'SUPER works in fieldless child accessing field-heavy base');
}

# ============================================================
# Safety: cross-class method dispatch, unblessed refs, bless-into-class
# ============================================================

{
    class SafetyC {
        field $x = "C";
        method x { $x }
    }

    # Unblessed ref
    eval { SafetyC::x({}) };
    like($@, qr/Cannot invoke method/, 'Method on unblessed ref gives error, not segfault');

    # Bless into class is forbidden
    eval { bless {}, "SafetyC" };
    like($@, qr/Attempt to bless into a class/,
        'Cannot bless into a class');

    # @ISA is read-only
    eval { push @SafetyC::ISA, "SomeOther" };
    like($@, qr/Modification of a read-only value/,
        '@ISA of class is read-only');
}

# ============================================================
# Weakrefs to class instances with fields
# ============================================================

{
    use Scalar::Util 'weaken';
    class WeakRefTest2 {
        field $x :param;
        method x { $x }
    }
    class WeakRefChild2 :isa(WeakRefTest2) {
        field $y :param;
        method y { $y }
    }

    my $obj = WeakRefChild2->new(x => "hello", y => "world");
    my $weak = $obj;
    weaken($weak);
    ok(defined($weak), 'Weakref alive while strong ref exists');
    is($weak->x, "hello", 'Weakref can access base field');
    is($weak->y, "world", 'Weakref can access child field');
    undef $obj;
    ok(!defined($weak), 'Weakref cleared after strong ref undef');
}

# ============================================================
# Class objects as field values
# ============================================================

{
    class ValueInner {
        field $val :param;
        method val { $val }
    }
    class ValueOuter {
        field $inner;
        ADJUST { $inner = ValueInner->new(val => 42) }
        method inner_val { $inner->val }
    }
    class ValueOuterChild :isa(ValueOuter) {
        field $extra = "extra";
        method extra { $extra }
    }

    my $obj = ValueOuterChild->new;
    is($obj->inner_val, 42, 'Class object stored in field works through inheritance');
    is($obj->extra, "extra", 'Child field works alongside object-valued base field');
}

# ============================================================
# Exception in ADJUST during construction
# ============================================================

{
    class AdjDieBase {
        field $x :param = "ok";
        method x { $x }
    }
    class AdjDieChild :isa(AdjDieBase) {
        field $y = "child-ok";
        ADJUST { die "boom\n" if $self->x eq "trigger" }
        method y { $y }
    }

    my $ok = AdjDieChild->new;
    is($ok->x, "ok", 'Normal construction works');
    is($ok->y, "child-ok", 'Normal construction sets child field');

    eval { AdjDieChild->new(x => "trigger") };
    is($@, "boom\n", 'ADJUST die is catchable');

    my $ok2 = AdjDieChild->new;
    is($ok2->x, "ok", 'Construction works after prior ADJUST failure');
}

# ============================================================
# Circular references in fields
# ============================================================

{
    class CircNode {
        field $partner;
        field $name :param;
        method set_partner { $partner = $_[0] }
        method partner { $partner }
        method name { $name }
    }
    class CircNodeChild :isa(CircNode) {
        field $tag :param = "child";
        method tag { $tag }
    }

    my $a = CircNodeChild->new(name => "A");
    my $b = CircNodeChild->new(name => "B");
    $a->set_partner($b);
    $b->set_partner($a);
    is($a->partner->name, "B", 'Circular ref A->B works');
    is($b->partner->name, "A", 'Circular ref B->A works');
    # Cleanup (will leak, but should not segfault)
    $a->set_partner(undef);
    $b->set_partner(undef);
    pass('Circular reference cleanup did not segfault');
}

# ============================================================
# Two independent inheritance chains in same scope (unit syntax)
# ============================================================

fresh_perl_is(<<'CODE', "ab cd\n", {}, 'Two independent unit-syntax chains in same scope');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class ChainABase;
    field $a = "a"; method a { $a }
    class ChainAChild :isa(ChainABase);
    field $b = "b"; method b { $b }

    class ChainBBase;
    field $c = "c"; method c { $c }
    class ChainBChild :isa(ChainBBase);
    field $d = "d"; method d { $d }
}
my $ac = ChainAChild->new;
my $bc = ChainBChild->new;
print $ac->a, $ac->b, " ", $bc->c, $bc->d, "\n";
CODE

# ============================================================
# Block class inside unit class scope, inheriting from it
# ============================================================

fresh_perl_is(<<'CODE', "outer inner\n", {}, 'Block class inside unit class scope');
use v5.36;
use feature 'class'; no warnings 'experimental::class';
{
    class UnitOuter;
    field $x = "outer"; method x { $x }
    {
        class BlockInner :isa(UnitOuter) {
            field $y = "inner"; method y { $y }
        }
    }
}
my $obj = BlockInner->new;
print $obj->x, " ", $obj->y, "\n";
CODE

done_testing;
