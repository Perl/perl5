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

Tests for combinations of field attributes (:param, :reader, :writer)
and their interactions.

=cut

# :param + :reader
{
    class AttrCombo1 {
        field $x :param :reader;
    }

    my $obj = AttrCombo1->new(x => "hello");
    is($obj->x, "hello", ':param + :reader works');
}

# :param + :writer
{
    class AttrCombo2 {
        field $x :param :writer :reader;
    }

    my $obj = AttrCombo2->new(x => "initial");
    is($obj->x, "initial", ':param + :writer + :reader initial value');
    $obj->set_x("modified");
    is($obj->x, "modified", ':param + :writer + :reader after set');
}

# :param with custom name + :reader
{
    class AttrCombo3 {
        field $x :param(initial_x) :reader;
    }

    my $obj = AttrCombo3->new(initial_x => "value");
    is($obj->x, "value", ':param(custom) + :reader works');
}

# :param with custom name + :reader with custom name
{
    class AttrCombo4 {
        field $x :param(init_val) :reader(get_val);
    }

    my $obj = AttrCombo4->new(init_val => "test");
    is($obj->get_val, "test", ':param(custom) + :reader(custom) works');

    # Original names should not exist
    ok(!eval { $obj->x }, 'default reader name does not exist');
}

# :param with custom name + :writer with custom name
{
    class AttrCombo5 {
        field $x :param(init_x) :reader :writer(put_x);
    }

    my $obj = AttrCombo5->new(init_x => "start");
    is($obj->x, "start", ':param(custom) + :writer(custom) initial');
    $obj->put_x("end");
    is($obj->x, "end", ':param(custom) + :writer(custom) after write');

    # Default writer name should not exist
    ok(!eval { $obj->set_x("nope") }, 'default writer name does not exist');
}

# :param + :reader + :writer all together
{
    class AttrCombo6 {
        field $val :param :reader :writer;
    }

    my $obj = AttrCombo6->new(val => 42);
    is($obj->val, 42, 'triple combo: read initial param');
    my $ret = $obj->set_val(99);
    is($obj->val, 99, 'triple combo: read after write');
    is($ret, $obj, 'triple combo: writer returns instance');
}

# :param + :reader + :writer all with custom names
{
    class AttrCombo7 {
        field $internal :param(p) :reader(get_it) :writer(set_it);
    }

    my $obj = AttrCombo7->new(p => "start");
    is($obj->get_it, "start", 'all-custom combo: reader');
    $obj->set_it("end");
    is($obj->get_it, "end", 'all-custom combo: writer then reader');

    # None of the default names should work
    ok(!eval { $obj->internal }, 'default reader unavailable');
    ok(!eval { $obj->set_internal("x") }, 'default writer unavailable');
}

# :reader with default value (no :param)
{
    class AttrCombo8 {
        field $x :reader = "default";
    }

    is(AttrCombo8->new->x, "default", ':reader with default value');
}

# :writer with default value (no :param)
{
    class AttrCombo9 {
        field $x :reader :writer = "default";
    }

    my $obj = AttrCombo9->new;
    is($obj->x, "default", ':writer with default value initial');
    $obj->set_x("changed");
    is($obj->x, "changed", ':writer with default value after set');
}

# :param with //= and :reader
{
    class AttrCombo10 {
        field $x :param :reader //= "fallback";
    }

    is(AttrCombo10->new->x, "fallback",
        ':param //= with :reader uses fallback when missing');
    is(AttrCombo10->new(x => undef)->x, "fallback",
        ':param //= with :reader uses fallback when undef');
    is(AttrCombo10->new(x => 0)->x, 0,
        ':param //= with :reader keeps falsy defined value');
    is(AttrCombo10->new(x => "val")->x, "val",
        ':param //= with :reader keeps truthy value');
}

# :param with ||= and :reader
{
    class AttrCombo11 {
        field $x :param :reader ||= "fallback";
    }

    is(AttrCombo11->new->x, "fallback",
        ':param ||= with :reader uses fallback when missing');
    is(AttrCombo11->new(x => 0)->x, "fallback",
        ':param ||= with :reader uses fallback when false');
    is(AttrCombo11->new(x => "val")->x, "val",
        ':param ||= with :reader keeps truthy value');
}

# Multiple fields with various attribute combos in same class
{
    class AttrCombo12 {
        field $a :param :reader;
        field $b :param :reader :writer;
        field $c :reader = "const";
        field $d :param(d_init) :reader(get_d) :writer(put_d);
    }

    my $obj = AttrCombo12->new(a => 1, b => 2, d_init => 4);
    is($obj->a, 1, 'multi-combo: a via :param :reader');
    is($obj->b, 2, 'multi-combo: b initial');
    $obj->set_b(22);
    is($obj->b, 22, 'multi-combo: b after write');
    is($obj->c, "const", 'multi-combo: c default with :reader');
    is($obj->get_d, 4, 'multi-combo: d via custom names');
    $obj->put_d(44);
    is($obj->get_d, 44, 'multi-combo: d after custom write');
}

# Attribute combos across inheritance
{
    class AttrComboBase1 {
        field $x :param :reader;
        field $y :param :reader :writer;
    }
    class AttrComboChild1 :isa(AttrComboBase1) {
        field $z :param(z_val) :reader(get_z) :writer(put_z);
    }

    my $obj = AttrComboChild1->new(x => "X", y => "Y", z_val => "Z");
    is($obj->x, "X", 'inherited :param :reader');
    is($obj->y, "Y", 'inherited :param :reader :writer read');
    $obj->set_y("YY");
    is($obj->y, "YY", 'inherited :writer works in child');
    is($obj->get_z, "Z", 'child custom :reader');
    $obj->put_z("ZZ");
    is($obj->get_z, "ZZ", 'child custom :writer');
}

# :reader on array field
{
    class AttrComboArr1 {
        field @items :reader = (1, 2, 3);
    }

    my $obj = AttrComboArr1->new;
    ok(eq_array([$obj->items], [1, 2, 3]), ':reader on array field');
    is(scalar $obj->items, 3, ':reader on array field in scalar context');
}

# :reader on hash field
{
    class AttrComboHash1 {
        field %data :reader = (a => 1, b => 2);
    }

    my $obj = AttrComboHash1->new;
    ok(eq_hash({$obj->data}, {a => 1, b => 2}), ':reader on hash field');
    is(scalar $obj->data, 2, ':reader on hash field in scalar context');
}

# :param only works on scalar fields (array/hash :param tested in t/lib/croak/class)

# Writer returns the invocant for chaining
{
    class AttrComboChain1 {
        field $a :reader :writer = 0;
        field $b :reader :writer = 0;
    }

    my $obj = AttrComboChain1->new;
    my $ret = $obj->set_a(1)->set_b(2);
    is($obj->a, 1, 'chained writer: a set');
    is($obj->b, 2, 'chained writer: b set');
    is($ret, $obj, 'chained writer: returns same instance');
}

# :reader returns copies not internal references
{
    class AttrComboCopy1 {
        field $s :reader :writer = "original";
    }

    my $obj = AttrComboCopy1->new;
    my $copy = $obj->s;
    $copy = "mutated";
    is($obj->s, "original", ':reader returns a copy for scalars');
}

done_testing;
