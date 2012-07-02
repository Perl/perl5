#!perl

BEGIN {
    chdir 't';
    require './test.pl';
    *bar::is = *is;
}
plan 13;

{
  our sub foo { 42 }
  is foo, 42, 'calling our sub from same package';
  is &foo, 42, 'calling our sub from same package (amper)';
  package bar;
  sub bar::foo { 43 }
  { local $::TODO = ' ';
    is foo, 42, 'calling our sub from another package';
  }
  is &foo, 42, 'calling our sub from another package (amper)';
}
package bar;
is foo, 43, 'our sub falling out of scope';
is &foo, 43, 'our sub falling out of scope (called via amper)';
package main;
{
  sub bar::a { 43 }
  our sub a {
    if (shift) {
      package bar;
      is a, 43, 'our sub invisible inside itself';
      is &a, 43, 'our sub invisible inside itself (called via amper)';
    }
    42
  }
  a(1);
  sub bar::b { 43 }
  our sub b;
  our sub b {
    if (shift) {
      package bar;
      { local $::TODO = ' ';
        is b, 42, 'our sub visible inside itself after decl';
      }
      is &b, 42, 'our sub visible inside itself after decl (amper)';
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
  { local $::TODO = ' ';
    is c, 42, 'our sub foo; makes lex alias for existing sub';
  }
  is &c, 42, 'our sub foo; makes lex alias for existing sub (amper)';
}
{
  our sub d;
  sub bar::d { 'd43' }
  package bar;
  sub d { 'd42' }
  { local $::TODO = ' ';
    is eval { ::d },'d42', 'our sub foo; applies to subsequent sub foo {}';
  }
}
