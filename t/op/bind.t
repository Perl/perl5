#!./perl -w
# tests the bind operator

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;
use feature ":5.11";

plan tests => 42;

{
    my $x = '';
    my $y;
    $y := $x;
    ok defined($y), '$y binds to $x';
    $x++;
    ok $y, 'changing $x changes $y';
}

{
    my $x = '';
    my $y := $x;
    ok defined($y), 'my $y binds to $x';
    $x++;
    ok $y, 'changing $x changes $y';
}

{
    my ($x, $y);
    $x := $y;
    ok !defined($x), 'scalar binding leaves LHS undef';
    ok !defined($y), 'scalar binding leaves RHS undef';

    $x = 'a';
    is $x, 'a',     'bound scalar can be assigned to (LHS)';
    is $y, 'a',     'bound scalar can be assigned to (RHS)';

    my $z := $x;
    is $z, 'a',     'binding works in declaration';

    $y = 'b';
    is $x, 'b',     'three-way binding (1)';
    is $z, 'b',     'three-way binding (2)';
}

{
    my @x = (1);
    my @y;
    @y := @x;
    ok $y[0], '@y binds to @x';
    push @x, 2;
    ok $y[1], 'changing @x changes @y';
}

{
    my @x = (1);
    my @y := @x;
    ok $y[0], 'my @y binds to @x';
    push @x, 2;
    ok $y[1], 'changing @x changes @y';
}

{
    my %x = (a => 1);
    my %y;
    %y := %x;
    ok $y{a}, '%y binds to %x';
    $x{b} = 2;
    ok $y{b}, 'changing %x changes %y';
}

{
    my %x = (a => 1);
    my %y := %x;
    ok $y{a}, 'my %y binds to %x';
    $x{b} = 2;
    ok $y{b}, 'changing %x changes %y';
}

my $d = 0;
sub DESTROY {  $d = 1 }
{
    {
        my ($a, $b);
        $a := $b;
        $b := $a;

        $a = bless {}, 'main';
    }
    ok $d, 'binding both ways does not leak the contents';
}

$d = 0;
{
    my ($a, $b);
    $a = bless {}, 'main';
    $b = 3;
    $a := $b;
}
ok $d, 'previous value of RHS did not leak';


{
    my $x := 4;
    is $x, 4, 'can bind an int literal';
    ok !defined(eval { $x = 5; 5}), '... which makes the variable RO';
    $x := 6;
    is $x, 6, 'but rebinding works';
}

{
    my ($a, $b, $c) = (1, 2, 3);
    $a := $b;
    $a := $c;
    is $a, 3, 'last binding wins (value of LHS)';
    is $b, 2, 'binding leaves RHS unchanged';
    is $c, 3, 'biding preserves value of last $HS';
}

TODO: {
    todo_skip('bind our', 3);
    eval q{
    my $x = 5;
    our $y := $x;
    is $y, 5, 'can bind "our" to "my" (1)';
    $x = 6;
    is $y, 6, 'can bind "our" to "my" (2)';
    $y = 7;
    is $x, 7, 'can bind "our" to "my" (3)';
    };
    die if $@;
}

{
    my (@a, @b);
    @a = qw(me mo);
    @b = (3, 4);
    @a := @b;
    is join('|', @a), '3|4', 'array binding (LHS)'; 
    is join('|', @b), '3|4', 'array binding (RHS)'; 
    $a[2] = 'mi';
    is join('|', @a), '3|4|mi', 'bound array is updated on assignment (LHS)'; 
    is join('|', @b), '3|4|mi', 'bound array is updated on assignment (RHS)'; 
}

TODO: {
    todo_skip('bind aelem', 3);
    eval q{
    my ($b, @a) = (1..4);
    $a[1] := $b;
    is join('|', @a,), '2|4|3', 'array element binding (1)';
    $b = 5;
    is join('|', @a,), '2|5|3', 'array item binding worked (one way)';
    @a = ('a' .. 'z');
    is $b, 'b',                 'array item binding worked (other way, list)';
    };
    die if $@;
}

TODO: {
    todo_skip('bind helem', 2);
    eval q{
    my ($a, %h) = (4, foo => 'bar', 'arg' => 'l');
    $h{foo} := $a;
    is $h{foo}, 4,  'hash item binding (1)';
    $h{foo} = 'h';
    is $a, 'h',     'hash item binding (2)';
    };
    die if $@;
}

TODO: {
    todo_skip('bind ref to array');
    eval q{
    my @a := [3, 5];
    is join('|', @a), '3|5', ':= DWIMs on ref vs. non-ref';
    };
    die if $@;
}

{
    sub a1 { my $a := $_[0]; $a = 5 }
    my $x = 1;
    a1($x);
    is $x, 5, '$_[0] binding update caller\'s variable';
}

{
    sub a2 {
        my @a := @_;
        $a[1]  = 9;
    }
    my $x;
    a2(3, $x);
    is $x, 9, '@_ binding update caller\'s variable';
}

# vim: ft=perl sw=4 ts=4 expandtab
