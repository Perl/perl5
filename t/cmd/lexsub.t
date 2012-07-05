#!perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
    *bar::is = *is;
}
no warnings 'deprecated';
plan 21;

{
  our sub foo { 42 }
  is foo, 42, 'calling our sub from same package';
  is &foo, 42, 'calling our sub from same package (amper)';
  is do foo(), 42, 'calling our sub from same package (do)';
  package bar;
  sub bar::foo { 43 }
  is foo, 42, 'calling our sub from another package';
  is &foo, 42, 'calling our sub from another package (amper)';
  is do foo(), 42, 'calling our sub from another package (do)';
}
package bar;
is foo, 43, 'our sub falling out of scope';
is &foo, 43, 'our sub falling out of scope (called via amper)';
is do foo(), 43, 'our sub falling out of scope (called via amper)';
package main;
{
  sub bar::a { 43 }
  our sub a {
    if (shift) {
      package bar;
      is a, 43, 'our sub invisible inside itself';
      is &a, 43, 'our sub invisible inside itself (called via amper)';
      is do a(), 43, 'our sub invisible inside itself (called via do)';
    }
    42
  }
  a(1);
  sub bar::b { 43 }
  our sub b;
  our sub b {
    if (shift) {
      package bar;
      is b, 42, 'our sub visible inside itself after decl';
      is &b, 42, 'our sub visible inside itself after decl (amper)';
      is do b(), 42, 'our sub visible inside itself after decl (do)';
    }
    42
  }
  b(1)
}
sub c { 42 }
sub bar::c { 43 }
{
  our sub c;
  package bar;
  is c, 42, 'our sub foo; makes lex alias for existing sub';
  is &c, 42, 'our sub foo; makes lex alias for existing sub (amper)';
  is do c(), 42, 'our sub foo; makes lex alias for existing sub (do)';
}
{
  our sub d;
  sub bar::d { 'd43' }
  package bar;
  sub d { 'd42' }
  is eval ::d, 'd42', 'our sub foo; applies to subsequent sub foo {}';
}
{
  our sub e ($);
  is prototype "::e", '$', 'our sub with proto';
}
{
  # lexical subs (even our) override all keywords
  our sub if() { 42 }
  my $x = if if if;
  is $x, 42;
}
