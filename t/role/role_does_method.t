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

# --- Setup: roles and classes for testing ---

role Drawable {
    method draw { "draw" }
}

role Printable {
    method print_out { "print" }
}

role Composing :does(Drawable) {
    method extra { "extra" }
}

class Widget :does(Drawable) {
    field $name :param :reader;
}

class FancyWidget :isa(Widget) :does(Printable) {
}

class Unrelated {
    field $x :param;
}

# --- Nominal ->does method tests ---

# Basic: class composing role
{
    my $w = Widget->new(name => "test");
    ok($w->does('Drawable'), 'Widget instance ->does(Drawable)');
    ok(!$w->does('Printable'), 'Widget instance does not ->does(Printable)');
}

# Inheritance: subclass inherits role composition
{
    my $fw = FancyWidget->new(name => "fancy");
    ok($fw->does('Drawable'), 'FancyWidget inherits Drawable via Widget');
    ok($fw->does('Printable'), 'FancyWidget directly does Printable');
}

# Transitive: role composes role
{
    class TransWidget :does(Composing) {
        field $id :param;
    }
    my $tw = TransWidget->new(id => 1);
    ok($tw->does('Composing'), 'TransWidget directly does Composing');
    ok($tw->does('Drawable'), 'TransWidget transitively does Drawable (via Composing)');
}

# Class name (not instance)
{
    ok(Widget->does('Drawable'), 'Widget class ->does(Drawable)');
    ok(!Widget->does('Printable'), 'Widget class does not ->does(Printable)');
}

# Unrelated class does not compose role
{
    my $u = Unrelated->new(x => 1);
    ok(!$u->does('Drawable'), 'Unrelated class does not do Drawable');
}

# Non-existent role returns false
{
    my $w = Widget->new(name => "test");
    ok(!$w->does('No::Such::Role'), '->does with non-existent role returns false');
}

# ->does vs ->DOES: both nominal for now (DOES becomes structural in 6B)
{
    my $w = Widget->new(name => "test");
    ok($w->does('Drawable'), '->does returns true for composed role');
    ok($w->DOES('Drawable'), '->DOES returns true for composed role');
}

# --- Infix `does` operator tests ---

# Basic infix
{
    my $w = Widget->new(name => "test");
    ok($w does Drawable, 'infix: $w does Drawable');
    ok(!($w does Printable), 'infix: $w does not do Printable');
}

# Infix with inheritance
{
    my $fw = FancyWidget->new(name => "fancy");
    ok($fw does Drawable, 'infix: FancyWidget does Drawable (inherited)');
    ok($fw does Printable, 'infix: FancyWidget does Printable (direct)');
}

# Infix transitive
{
    class TransWidget2 :does(Composing) {
        field $id :param;
    }
    my $tw = TransWidget2->new(id => 1);
    ok($tw does Composing, 'infix: TransWidget2 does Composing');
    ok($tw does Drawable, 'infix: TransWidget2 does Drawable (transitive)');
}

# Infix with class name (as string on LHS)
{
    ok('Widget' does Drawable, 'infix: Widget class does Drawable');
    ok(!('Widget' does Printable), 'infix: Widget class does not do Printable');
}

# Infix in conditional
{
    my $w = Widget->new(name => "test");
    my $result = $w does Drawable ? "yes" : "no";
    is($result, "yes", 'infix does works in ternary');
}

# --- Structural ->DOES tests ---

# Basic: class composes role, no overrides -- DOES true
{
    my $w = Widget->new(name => "test");
    ok($w->DOES('Drawable'), 'DOES: Widget fulfills Drawable contract');
}

# Subclass overrides role method -- DOES false
role Renderable {
    method render { "base render" }
}

class Canvas :does(Renderable) {
    field $id :param;
}

class FancyCanvas :isa(Canvas) {
    method render { "fancy render" }
}

{
    my $c = Canvas->new(id => 1);
    ok($c->DOES('Renderable'), 'DOES: Canvas fulfills Renderable (no override)');
    ok($c->does('Renderable'), 'does: Canvas nominally does Renderable');

    my $fc = FancyCanvas->new(id => 2);
    ok(!$fc->DOES('Renderable'), 'DOES: FancyCanvas breaks Renderable (overrides render)');
    ok($fc->does('Renderable'), 'does: FancyCanvas still nominally does Renderable');
}

# Class itself overrides role method -- DOES false
role Greetable2 {
    method greet { "hello" }
}

class Greeter2 :does(Greetable2) {
    field $name :param;
    method greet { "hi from $name" }
}

{
    my $g = Greeter2->new(name => "world");
    ok(!$g->DOES('Greetable2'), 'DOES: Greeter2 overrides greet, breaks contract');
    ok($g->does('Greetable2'), 'does: Greeter2 still nominally does Greetable2');
}

# Required method satisfied -- DOES true
role Describable {
    method describe;
}

class Item :does(Describable) {
    field $label :param;
    method describe { "item: $label" }
}

{
    my $item = Item->new(label => "test");
    ok($item->DOES('Describable'), 'DOES: Item satisfies Describable required method');
    ok($item->does('Describable'), 'does: Item nominally does Describable');
}

# ->does true but ->DOES false (the disagreement case from ROLE_ALGEBRA.md 11.4)
role Contract {
    method fulfill { "fulfilled" }
    method verify;
}

class Worker :does(Contract) {
    field $id :param;
    method verify { 1 }
}

class OverrideWorker :isa(Worker) {
    method fulfill { "overridden" }
}

{
    my $w = Worker->new(id => 1);
    ok($w->does('Contract'), 'does/DOES agree: Worker does Contract');
    ok($w->DOES('Contract'), 'does/DOES agree: Worker DOES Contract');

    my $ow = OverrideWorker->new(id => 2);
    ok($ow->does('Contract'), 'Disagreement: OverrideWorker does Contract (nominal)');
    ok(!$ow->DOES('Contract'), 'Disagreement: OverrideWorker !DOES Contract (structural)');
}

done_testing;
