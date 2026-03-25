#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

# Basic DOES and isa semantics
{
    role Greetable {
        method greet { "hello" }
    }

    class Greeter :does(Greetable) {
        field $name :param;
        method name { $name }
    }

    my $g = Greeter->new(name => "World");

    # DOES returns true for composed roles
    ok($g->DOES('Greetable'), 'instance DOES composed role');
    ok($g->DOES('Greeter'),   'instance DOES its own class');
    ok($g->DOES('UNIVERSAL'), 'instance DOES UNIVERSAL');

    # isa returns false for roles (roles are not classes)
    ok(!$g->isa('Greetable'), 'instance isa NOT the role');
    ok($g->isa('Greeter'),    'instance isa its own class');
    ok($g->isa('UNIVERSAL'),  'instance isa UNIVERSAL');

    # Method dispatch still works
    is($g->greet, 'hello', 'composed role method works');
    is($g->name,  'World', 'class own method works');
}

# DOES on class name (non-instance)
{
    role Taggable {
        method tag { "tagged" }
    }

    class Tagged :does(Taggable) {
        field $x :param;
    }

    ok(Tagged->DOES('Taggable'), 'class name DOES composed role');
    ok(Tagged->DOES('Tagged'),   'class name DOES itself');
    ok(!Tagged->isa('Taggable'), 'class name isa NOT the role');
}

# Transitive DOES (role composes role)
{
    role Inner {
        method inner { "inner" }
    }

    role Outer :does(Inner) {
        method outer { "outer" }
    }

    class MyClass :does(Outer) {
        field $x :param;
    }

    my $obj = MyClass->new(x => 1);

    ok($obj->DOES('Outer'), 'instance DOES directly composed role');
    ok($obj->DOES('Inner'), 'instance DOES transitively composed role');
    ok(!$obj->isa('Outer'), 'instance isa NOT directly composed role');
    ok(!$obj->isa('Inner'), 'instance isa NOT transitively composed role');

    is($obj->inner, 'inner', 'transitive role method works');
    is($obj->outer, 'outer', 'direct role method works');
}

# DOES inherited from superclass
{
    role Describable {
        field $description :param;
        method describe { $description }
    }

    class Base :does(Describable) {
        field $id :param;
        method id { $id }
    }

    class Child :isa(Base) {
        field $name :param;
        method name { $name }
    }

    my $c = Child->new(id => 1, name => "test", description => "a test");

    ok($c->DOES('Describable'), 'child instance DOES role composed by parent');
    ok($c->isa('Base'),         'child instance isa parent');
    ok(!$c->isa('Describable'), 'child instance isa NOT the role');

    is($c->describe, 'a test', 'inherited role method works');
    is($c->id,       1,        'parent method works');
    is($c->name,     'test',   'child method works');
}

# DOES with multiple roles
{
    role R1 {
        method r1 { "r1" }
    }

    role R2 {
        method r2 { "r2" }
    }

    class Multi :does(R1) :does(R2) {
        field $x :param;
    }

    my $m = Multi->new(x => 1);

    ok($m->DOES('R1'), 'instance DOES first role');
    ok($m->DOES('R2'), 'instance DOES second role');
    ok(!$m->isa('R1'), 'instance isa NOT first role');
    ok(!$m->isa('R2'), 'instance isa NOT second role');

    is($m->r1, 'r1', 'first role method works');
    is($m->r2, 'r2', 'second role method works');
}

# DOES with role fields
{
    role HasName {
        field $name :param :reader;
    }

    role HasAge {
        field $age :param :reader;
    }

    class Person :does(HasName) :does(HasAge) {
        field $email :param :reader;
    }

    my $p = Person->new(name => "Alice", age => 30, email => 'alice@example.com');

    ok($p->DOES('HasName'), 'DOES role with field');
    ok($p->DOES('HasAge'),  'DOES second role with field');

    is($p->name,  'Alice',             'role field reader works');
    is($p->age,   30,                  'second role field reader works');
    is($p->email, 'alice@example.com', 'class field reader works');
}

# DOES with ADJUST blocks
{
    role WithAdjust {
        field $adjusted :reader = 0;

        ADJUST {
            $adjusted = 42;
        }
    }

    class AdjustConsumer :does(WithAdjust) {
        field $y :param;
    }

    my $obj = AdjustConsumer->new(y => 1);

    ok($obj->DOES('WithAdjust'), 'DOES role with ADJUST');
    is($obj->adjusted, 42,       'role ADJUST block ran correctly');
}

# DOES returns false for unrelated roles
{
    role Unrelated {
        method unrelated { "unrelated" }
    }

    role Composed {
        method composed { "composed" }
    }

    class OnlyComposed :does(Composed) {
        field $x :param;
    }

    my $obj = OnlyComposed->new(x => 1);

    ok($obj->DOES('Composed'),   'DOES the composed role');
    ok(!$obj->DOES('Unrelated'), 'does NOT DOES an unrelated role');
}

# Deep transitive chain: A :does B :does C :does D
{
    role D {
        method d { "d" }
    }

    role C :does(D) {
        method c { "c" }
    }

    role B :does(C) {
        method b { "b" }
    }

    class A :does(B) {
        field $x :param;
    }

    my $a = A->new(x => 1);

    ok($a->DOES('B'), 'DOES direct role in chain');
    ok($a->DOES('C'), 'DOES transitive role (depth 2)');
    ok($a->DOES('D'), 'DOES transitive role (depth 3)');

    is($a->b, 'b', 'direct role method in chain');
    is($a->c, 'c', 'transitive role method (depth 2)');
    is($a->d, 'd', 'transitive role method (depth 3)');
}

# Superclass + role combination with DOES
{
    role Serializable {
        method serialize { "serialized" }
    }

    class BaseObj {
        field $id :param :reader;
    }

    class SubObj :isa(BaseObj) :does(Serializable) {
        field $name :param :reader;
    }

    class GrandChild :isa(SubObj) {
        field $extra :param :reader;
    }

    my $gc = GrandChild->new(id => 1, name => "gc", extra => "x");

    ok($gc->DOES('Serializable'), 'grandchild DOES role from parent');
    ok($gc->isa('SubObj'),        'grandchild isa parent');
    ok($gc->isa('BaseObj'),       'grandchild isa grandparent');
    ok(!$gc->isa('Serializable'), 'grandchild isa NOT the role');

    is($gc->serialize, 'serialized', 'role method via grandchild works');
    is($gc->id,        1,            'grandparent method works');
    is($gc->name,      'gc',         'parent method works');
    is($gc->extra,     'x',          'own method works');
}

done_testing;
