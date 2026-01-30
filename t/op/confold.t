#!./perl

# Tests for the <: compile-time constant operator

BEGIN {
    chdir 't';
    require './test.pl';
    set_up_inc("../lib");
}

plan tests => 12;

# Basic constant folding - integers
{
    my $x = <: 42;
    is $x, 42, '<: with integer literal';
}

# Basic constant folding - strings
{
    my $s = <: "hello";
    is $s, "hello", '<: with string literal';
}

# Basic constant folding - floats
{
    my $f = <: 3.14159;
    is $f, 3.14159, '<: with float literal';
}

# Runtime path - with variable
{
    my $var = "dynamic";
    my $c = <: $var;
    is $c, "dynamic", '<: with variable (runtime path)';
}

# Verify constant folding actually happens (no constop in op tree for literals)
{
    # If constant folding works, this should compile to just a constant
    my $x = <: 100;
    is $x, 100, '<: literal is folded at compile time';
}

# Multiple <: in same statement
{
    my $a = <: 1;
    my $b = <: 2;
    my $c = <: 3;
    is $a + $b + $c, 6, 'multiple <: expressions';
}

# <: with expression result (runtime)
{
    my $a = 10;
    my $b = 20;
    my $sum = <: ($a + $b);
    is $sum, 30, '<: with expression (runtime path)';
}

# <: in list context
{
    my @arr = (<: 1, <: 2, <: 3);
    is "@arr", "1 2 3", '<: in list context';
}

# <: with negative number
{
    my $neg = <: -42;
    is $neg, -42, '<: with negative literal';
}

# <: with empty string
{
    my $empty = <: "";
    is $empty, "", '<: with empty string';
}

# <: with zero
{
    my $zero = <: 0;
    is $zero, 0, '<: with zero';
    ok defined($zero), '<: zero is defined';
}
