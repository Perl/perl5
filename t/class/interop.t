#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.36;
use feature 'class';
no warnings qw( experimental::class experimental::builtin );

use builtin qw( blessed reftype refaddr );
use Scalar::Util qw( weaken isvstring looks_like_number );

=pod

Tests for interoperability between the class system and traditional
Perl OO, builtins, and common idioms.

=cut

# ============================================================
# blessed(), ref(), reftype(), refaddr() on class instances
# ============================================================

{
    class Interop1 {
        field $x :param :reader;
    }

    my $obj = Interop1->new(x => 42);
    is(ref $obj, "Interop1", 'ref() on class instance');
    is(blessed $obj, "Interop1", 'blessed() on class instance');
    is(reftype $obj, "OBJECT", 'reftype() is OBJECT');
    ok(refaddr($obj) > 0, 'refaddr() returns positive integer');
}

# ============================================================
# isa() - both method and function forms
# ============================================================

{
    class InteropIsaBase1 { }
    class InteropIsaChild1 :isa(InteropIsaBase1) { }
    class InteropIsaGC1 :isa(InteropIsaChild1) { }

    my $obj = InteropIsaGC1->new;

    # Method form
    ok($obj->isa("InteropIsaGC1"), 'isa own class');
    ok($obj->isa("InteropIsaChild1"), 'isa parent');
    ok($obj->isa("InteropIsaBase1"), 'isa grandparent');
    ok(!$obj->isa("Nonexistent"), 'not isa random class');

    # `isa` operator (v5.36)
    ok($obj isa InteropIsaGC1, 'isa operator: own class');
    ok($obj isa InteropIsaBase1, 'isa operator: grandparent');
    ok(!($obj isa Nonexistent::Class), 'isa operator: false for random');

    # UNIVERSAL::isa function form
    ok(UNIVERSAL::isa($obj, "InteropIsaBase1"),
        'UNIVERSAL::isa function form');
}

# ============================================================
# DOES()
# ============================================================

{
    class InteropDoes1 { }
    class InteropDoes2 :isa(InteropDoes1) { }

    my $obj = InteropDoes2->new;
    ok($obj->DOES("InteropDoes2"), 'DOES own class');
    ok($obj->DOES("InteropDoes1"), 'DOES parent class');
    ok(!$obj->DOES("Something::Else"), 'DOES false for random class');
}

# ============================================================
# can()
# ============================================================

{
    class InteropCan1 {
        field $x :reader = 1;
        method foo { "foo" }
    }
    class InteropCan2 :isa(InteropCan1) {
        method bar { "bar" }
    }

    my $obj = InteropCan2->new;
    ok($obj->can("foo"), 'can("foo") inherited method');
    ok($obj->can("bar"), 'can("bar") own method');
    ok($obj->can("x"), 'can("x") reader accessor');
    ok($obj->can("new"), 'can("new") constructor');
    ok(!$obj->can("nonexistent_xyz"), 'can() false for missing method');

    # can() returns a code ref
    my $cref = $obj->can("foo");
    is(ref $cref, "CODE", 'can() returns CODE ref');
}

# ============================================================
# Stringification and numification
# ============================================================

{
    class InteropStr1 { }

    my $obj = InteropStr1->new;

    # Default stringification
    like("$obj", qr/^InteropStr1=OBJECT\(0x[0-9a-f]+\)$/i,
        'Default stringification format');

    # Default numification (refaddr)
    is($obj + 0, refaddr($obj), 'Default numification is refaddr');
}

# Custom overloaded stringification
{
    class InteropStr2 {
        field $name :param :reader;
        use overload
            '""' => sub { "InteropStr2<" . $_[0]->name . ">" },
            fallback => 1;
    }

    my $obj = InteropStr2->new(name => "test");
    is("$obj", "InteropStr2<test>", 'Overloaded stringify');
}

# ============================================================
# Comparison operators
# ============================================================

{
    class InteropCmp1 { }

    my $a = InteropCmp1->new;
    my $b = InteropCmp1->new;
    my $c = $a;

    ok($a == $c, '== on same instance');
    ok($a != $b, '!= on different instances');
    ok(!($a == $b), '== false on different instances');
}

# ============================================================
# Class instances passed to traditional Perl code
# ============================================================

{
    class InteropPass1 {
        field $value :param :reader;
    }

    # Passing to a sub that expects blessed refs
    sub legacy_handler {
        my ($obj) = @_;
        return blessed($obj) . ":" . $obj->value;
    }

    my $obj = InteropPass1->new(value => "data");
    is(legacy_handler($obj), "InteropPass1:data",
        'Class instance works with legacy code expecting blessed refs');
}

# ============================================================
# Class instances in data structures
# ============================================================

{
    class InteropDS1 {
        field $id :param :reader;
    }

    # In arrays
    my @objs = map { InteropDS1->new(id => $_) } 1..5;
    is(scalar @objs, 5, 'Objects in array');
    is($objs[2]->id, 3, 'Array element method call');

    # In hashes
    my %map = map { ("k$_" => InteropDS1->new(id => $_)) } 1..3;
    is($map{k2}->id, 2, 'Hash value method call');

    # Sorting
    my @sorted = sort { $b->id <=> $a->id } @objs;
    is($sorted[0]->id, 5, 'Sorted objects: first');
    is($sorted[4]->id, 1, 'Sorted objects: last');

    # grep/map
    my @even = grep { $_->id % 2 == 0 } @objs;
    is(scalar @even, 2, 'grep on objects');
    my @doubled = map { $_->id * 2 } @objs;
    ok(eq_array(\@doubled, [2, 4, 6, 8, 10]), 'map on objects');
}

# ============================================================
# Class instance as argument to builtin functions
# ============================================================

{
    class InteropBuiltin1 {
        field $x :reader = "test";
    }

    my $obj = InteropBuiltin1->new;

    # defined
    ok(defined $obj, 'defined on object');

    # ref
    is(ref $obj, "InteropBuiltin1", 'ref on object');

    # Array/hash of objects with scalar()
    my @arr = ($obj, $obj);
    is(scalar @arr, 2, 'scalar on array of objects');
}

# ============================================================
# Interaction with eval/die
# ============================================================

{
    class InteropEval1 {
        field $x :param :reader;
        method fail { die "InteropEval1 error\n" }
    }

    my $obj = InteropEval1->new(x => "safe");
    eval { $obj->fail };
    is($@, "InteropEval1 error\n", 'die from method caught by eval');
    is($obj->x, "safe", 'Object still usable after caught die');

    # Object as die argument
    eval { die $obj };
    is(ref $@, "InteropEval1", 'Object thrown as exception');
    is($@->x, "safe", 'Thrown object retains fields');
}

# ============================================================
# Interaction with local()
# ============================================================

{
    class InteropLocal1 {
        field $x :reader = "default";
    }

    our $global_obj = InteropLocal1->new;
    is($global_obj->x, "default", 'Global object before local');

    {
        local $global_obj = InteropLocal1->new;
        is($global_obj->x, "default", 'Localized object');
    }
    is($global_obj->x, "default", 'Global object restored after local');
}

# ============================================================
# Class object with Scalar::Util functions
# ============================================================

{
    class InteropSU1 {
        field $x :reader = 42;
    }

    my $obj = InteropSU1->new;

    # weaken
    my $weak = $obj;
    weaken($weak);
    ok(defined $weak, 'weaken: ref alive');
    undef $obj;
    ok(!defined $weak, 'weaken: ref cleared');
}

# ============================================================
# Class with traditional Perl OO in same program
# ============================================================

{
    package LegacyOO1 {
        sub new {
            my ($class, %args) = @_;
            return bless \%args, $class;
        }
        sub value { return $_[0]->{value} }
    }

    class ModernOO1 {
        field $value :param :reader;
    }

    my $legacy = LegacyOO1->new(value => "old");
    my $modern = ModernOO1->new(value => "new");

    is($legacy->value, "old", 'Legacy OO works');
    is($modern->value, "new", 'Modern class works');
    is(ref $legacy, "LegacyOO1", 'Legacy ref type');
    is(ref $modern, "ModernOO1", 'Modern ref type');
    is(reftype $legacy, "HASH", 'Legacy reftype is HASH');
    is(reftype $modern, "OBJECT", 'Modern reftype is OBJECT');
}

# ============================================================
# Class inheriting from traditional OO is NOT supported
# (traditional packages are not classes)
# ============================================================

{
    BEGIN {
        package LegacyBase1;
        sub new { bless {}, shift }
        sub legacy_method { "legacy" }
        $INC{"LegacyBase1.pm"} = 1;
    }

    # :isa requires a class, not a regular package
    ok(!eval q{
        class HybridChild1 :isa(LegacyBase1) {
            field $x :reader = "modern";
        }
        1;
    }, 'Cannot :isa from traditional package');
    like($@, qr/requires a class.*is not one/,
        'Error: :isa target must be a class');
}

# ============================================================
# Multiple dispatch: method resolution order
# ============================================================

{
    class InteropMRO1 {
        method m { "base" }
    }
    class InteropMRO2 :isa(InteropMRO1) {
        method m { "child" }
    }
    class InteropMRO3 :isa(InteropMRO2) { }  # inherits m from MRO2

    is(InteropMRO1->new->m, "base", 'MRO: base');
    is(InteropMRO2->new->m, "child", 'MRO: override');
    is(InteropMRO3->new->m, "child", 'MRO: grandchild inherits override');
}

# ============================================================
# Interaction with for/foreach
# ============================================================

{
    class InteropFor1 {
        field $n :param :reader;
    }

    my @objs = map { InteropFor1->new(n => $_) } 1..3;
    my @collected;
    for my $obj (@objs) {
        push @collected, $obj->n;
    }
    ok(eq_array(\@collected, [1, 2, 3]), 'for loop over objects');

    # C-style for
    my $sum = 0;
    for (my $i = 0; $i < @objs; $i++) {
        $sum += $objs[$i]->n;
    }
    is($sum, 6, 'C-style for with objects');
}

# ============================================================
# Object in boolean context
# ============================================================

{
    class InteropBool1 { }

    my $obj = InteropBool1->new;
    ok($obj, 'Object is true in boolean context');
    ok(!!$obj, 'Double-negated object is true');

    if ($obj) {
        pass('Object in if condition is true');
    } else {
        fail('Object in if condition should be true');
    }
}

# ============================================================
# sprintf/printf with objects
# ============================================================

{
    class InteropSprintf1 {
        use overload '""' => sub { "custom-string" }, fallback => 1;
    }

    my $obj = InteropSprintf1->new;
    is(sprintf("%s", $obj), "custom-string", 'sprintf %s with overloaded object');
}

done_testing;
