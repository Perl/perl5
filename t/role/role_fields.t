#!/usr/bin/perl

use v5.42;
use feature 'class';
no warnings 'experimental::class';

use Test::More;

# Basic field composition
{
    role HasName {
        field $name :param;
        method name { $name }
    }

    class Person :does(HasName) {
        field $age :param;
        method age { $age }
    }

    my $p = Person->new(name => "Alice", age => 30);
    is($p->name, 'Alice', 'role field accessible via role method');
    is($p->age,  30,      'class field works alongside role field');
}

# Multiple roles with fields
{
    role HasX {
        field $x :param;
        method x { $x }
    }

    role HasY {
        field $y :param;
        method y { $y }
    }

    class Point :does(HasX) :does(HasY) {
        method to_string { $self->x . "," . $self->y }
    }

    my $p = Point->new(x => 3, y => 4);
    is($p->x,         3,     'first role field');
    is($p->y,         4,     'second role field');
    is($p->to_string, '3,4', 'class method using role fields');
}

# Role field with default value
{
    role HasCount {
        field $count = 0;
        method count { $count }
        method increment { $count++ }
    }

    class Counter :does(HasCount) {
        field $label :param;
        method label { $label }
    }

    my $c = Counter->new(label => "clicks");
    is($c->count, 0,        'role field default value');
    $c->increment;
    is($c->count, 1,        'role field mutation works');
    is($c->label, 'clicks', 'class field alongside defaulted role field');
}

# Role field with :param and default
{
    role Configurable {
        field $config :param = "default";
        method config { $config }
    }

    class App :does(Configurable) {
        field $name :param;
        method name { $name }
    }

    my $a1 = App->new(name => "app1");
    is($a1->config, 'default', 'role :param field uses default when not provided');

    my $a2 = App->new(name => "app2", config => "custom");
    is($a2->config, 'custom', 'role :param field accepts value');
}

# Role with :reader field
{
    role HasTitle {
        field $title :param :reader;
    }

    class Book :does(HasTitle) {
        field $pages :param :reader;
    }

    my $b = Book->new(title => "Perl Cookbook", pages => 968);
    is($b->title, 'Perl Cookbook', 'role :reader field');
    is($b->pages, 968,            'class :reader field');
}

# Field composition with inheritance
{
    role Describable {
        field $description :param;
        method description { $description }
    }

    class Base {
        field $id :param;
        method id { $id }
    }

    class Child :isa(Base) :does(Describable) {
        field $name :param;
        method name { $name }
    }

    my $c = Child->new(id => 1, name => "test", description => "a test");
    is($c->id,          1,        'inherited class field');
    is($c->description, 'a test', 'composed role field');
    is($c->name,        'test',   'own class field');
}

# Deep inheritance with roles at different levels
{
    role Tagged {
        field $tag :param = "none";
        method tag { $tag }
    }

    role Versioned {
        field $version :param = "1.0";
        method version { $version }
    }

    class GrandParent :does(Tagged) {
        field $gp :param;
        method gp { $gp }
    }

    class Parent :isa(GrandParent) :does(Versioned) {
        field $p :param;
        method p { $p }
    }

    class GrandChild :isa(Parent) {
        field $gc :param;
        method gc { $gc }
    }

    my $obj = GrandChild->new(gp => "gp", p => "p", gc => "gc",
                              tag => "important", version => "2.0");
    is($obj->gp,      'gp',        'grandparent field');
    is($obj->p,       'p',         'parent field');
    is($obj->gc,      'gc',        'grandchild field');
    is($obj->tag,     'important', 'role field from grandparent level');
    is($obj->version, '2.0',       'role field from parent level');
}

# Multi-consumer: same role composed into different classes
{
    role HasValue {
        field $value :param;
        method value { $value }
        method doubled { $value * 2 }
    }

    class IntHolder :does(HasValue) {
        field $label :param;
        method label { $label }
    }

    class FloatHolder :does(HasValue) {
        field $precision :param;
        method precision { $precision }
    }

    my $i = IntHolder->new(value => 5, label => "count");
    my $f = FloatHolder->new(value => 3.14, precision => 2);

    is($i->value,   5,         'first consumer: role field');
    is($i->doubled, 10,        'first consumer: role method using field');
    is($i->label,   'count',   'first consumer: own field');

    is($f->value,     3.14,    'second consumer: role field');
    is($f->doubled,   6.28,    'second consumer: role method using field');
    is($f->precision, 2,       'second consumer: own field');

    # Mutating one consumer doesn't affect the other
    is($i->value, 5, 'consumers are independent');
}

# Role ADJUST block with field initialization
{
    role Timestamped {
        field $created_at = 0;
        method created_at { $created_at }

        ADJUST {
            $created_at = 12345;
        }
    }

    class Record :does(Timestamped) {
        field $data :param;
        method data { $data }
    }

    my $r = Record->new(data => "info");
    is($r->created_at, 12345, 'role ADJUST set field value');
    is($r->data,       'info', 'class field unaffected by role ADJUST');
}

# Multiple fields in one role, some with :param, some with defaults
{
    role Rect {
        field $width :param;
        field $height :param;
        field $area = 0;

        ADJUST {
            $area = $width * $height;
        }

        method width  { $width }
        method height { $height }
        method area   { $area }
    }

    class Window :does(Rect) {
        field $title :param;
        method title { $title }
    }

    my $w = Window->new(title => "Main", width => 800, height => 600);
    is($w->title,  'Main',   'class field');
    is($w->width,  800,      'role :param field');
    is($w->height, 600,      'role :param field');
    is($w->area,   480000,   'role ADJUST computed from role fields');
}

# Role fields with class having no own fields
{
    role FullRole {
        field $a :param;
        field $b :param;
        method sum { $a + $b }
    }

    class Minimal :does(FullRole) { }

    my $m = Minimal->new(a => 3, b => 7);
    is($m->sum, 10, 'class with no own fields, only role fields');
}

# Multiple roles each with ADJUST blocks modifying their fields
{
    role Color {
        field $r :param = 0;
        field $g :param = 0;
        field $b :param = 0;
        field $hex = "";

        ADJUST {
            $hex = sprintf("#%02x%02x%02x", $r, $g, $b);
        }

        method hex { $hex }
    }

    role Size {
        field $w :param = 100;
        field $h :param = 100;
        field $pixels = 0;

        ADJUST {
            $pixels = $w * $h;
        }

        method pixels { $pixels }
    }

    class Canvas :does(Color) :does(Size) {
        field $name :param;
        method name { $name }
    }

    my $c = Canvas->new(name => "main", r => 255, g => 128, b => 0, w => 640, h => 480);
    is($c->name,   'main',      'class field');
    is($c->hex,    '#ff8000',   'first role ADJUST computed field');
    is($c->pixels, 307200,      'second role ADJUST computed field');
}

done_testing;
