#!perl

print "1..14\n";

{
  our sub foo { 42 }
  print "not " unless foo == 42;
  print "ok 1 - calling our sub from same package\n";
  print "not " unless &foo == 42;
  print "ok 2 - calling our sub from same package (amper)\n";
  package bar;
  sub bar::foo { 43 }
  print "not " unless foo == 42;
  print "ok 3 - calling our sub from another package # TODO\n";
  print "not " unless &foo == 42;
  print "ok 4 - calling our sub from another package (amper)\n";
}
package bar;
print "not " unless foo == 43;
print "ok 5 - our sub falling out of scope\n";
print "not " unless &foo == 43;
print "ok 6 - our sub falling out of scope (called via amper)\n";
package main;
{
  sub bar::a { 43 }
  our sub a {
    if (shift) {
      package bar;
      print "not " unless a == 43;
      print "ok 7 - our sub invisible inside itself\n";
      print "not " unless &a == 43;
      print "ok 8 - our sub invisible inside itself (called via amper)\n";
    }
    42
  }
  a(1);
  sub bar::b { 43 }
  our sub b;
  our sub b {
    if (shift) {
      package bar;
      print "not " unless b == 42;
      print "ok 9 - our sub visible inside itself after decl # TODO\n";
      print "not " unless &b == 42;
      print "ok 10 - our sub visible inside itself after decl (amper)\n";
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
  print "not " unless c == 42;
  print "ok 11 - our sub foo; makes lex alias for existing sub # TODO\n";
  print "not " unless &c == 42;
  print "ok 12 - our sub foo; makes lex alias for existing sub (amper)\n";
}
{
  our sub d;
  sub d { 'd42' }
  sub bar::d { 'd43' }
  package bar;
  print "not " unless d eq 'd42';
  print "ok 13 - our sub foo; applies to subsequent sub foo {} # TODO\n";
  print "not " unless &d eq 'd42';
  print "ok 14 - our sub foo; applies to subsequent sub foo {} (amper)\n";
}
