#!perl

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
    *bar::is = *is;
    *bar::like = *like;
}
no warnings 'deprecated';
plan 62;

# -------------------- our -------------------- #

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
  our sub if() { 42 }
  my $x = if if if;
  is $x, 42, 'lexical subs (even our) override all keywords';
  package bar;
  my $y = if if if;
  is $y, 42, 'our subs from other packages override all keywords';
}

# -------------------- state -------------------- #

sub on { $::TODO = ' ' }
sub off { $::TODO = undef }

use 5.01; # state
{
  state sub foo { 44 }
  isnt \&::foo, \&foo, 'state sub is not stored in the package';
  is eval foo, 44, 'calling state sub from same package';
  is eval &foo, 44, 'calling state sub from same package (amper)';
  is eval do foo(), 44, 'calling state sub from same package (do)';
  package bar;
  is eval foo, 44, 'calling state sub from another package';
  is eval &foo, 44, 'calling state sub from another package (amper)';
  is eval do foo(), 44, 'calling state sub from another package (do)';
}
package bar;
is foo, 43, 'state sub falling out of scope';
is &foo, 43, 'state sub falling out of scope (called via amper)';
is do foo(), 43, 'state sub falling out of scope (called via amper)';
{
  sub sa { 43 }
  state sub sa {
    if (shift) {
      is sa, 43, 'state sub invisible inside itself';
      is &sa, 43, 'state sub invisible inside itself (called via amper)';
      is do sa(), 43, 'state sub invisible inside itself (called via do)';
    }
    44
  }
  sa(1);
  sub sb { 43 }
  state sub sb;
  state sub sb {
    if (shift) {
      # ‘state sub foo{}’ creates a new pad entry, not reusing the forward
      #  declaration.  Being invisible inside itself, it sees the stub.
      eval{sb};
      like $@, qr/^Undefined subroutine &sb called at /,
        'state sub foo {} after forward declaration';
      eval{&sb};
      like $@, qr/^Undefined subroutine &sb called at /,
        'state sub foo {} after forward declaration (amper)';
      eval{do sb()};
      like $@, qr/^Undefined subroutine &sb called at /,
        'state sub foo {} after forward declaration (do)';
    }
    44
  }
  sb(1);
  sub sb2 { 43 }
  state sub sb2;
  sub sb2 {
    if (shift) {
      package bar;
      is sb2, 44, 'state sub visible inside itself after decl';
      is &sb2, 44, 'state sub visible inside itself after decl (amper)';
      is do sb2(), 44, 'state sub visible inside itself after decl (do)';
    }
    44
  }
  sb2(1);
  state sub sb3;
  {
    state sub sb3 { # new pad entry
      # The sub containing this comment is invisible inside itself.
      # So this one here will assign to the outer pad entry:
      sub sb3 { 47 }
    }
  }
  is eval{sb3}, 47,
    'sub foo{} applying to "state sub foo;" even inside state sub foo{}';
}
sub sc { 43 }
{
  state sub sc;
  eval{sc};
  like $@, qr/^Undefined subroutine &sc called at /,
     'state sub foo; makes no lex alias for existing sub';
  eval{&sc};
  like $@, qr/^Undefined subroutine &sc called at /,
     'state sub foo; makes no lex alias for existing sub (amper)';
  eval{do sc()};
  like $@, qr/^Undefined subroutine &sc called at /,
     'state sub foo; makes no lex alias for existing sub (do)';
}
package main;
{
  state sub se ($);
  is prototype eval{\&se}, '$', 'state sub with proto';
  is prototype "se", undef, 'prototype "..." ignores state subs';
}
{
  state sub if() { 44 }
  my $x = if if if;
  is $x, 44, 'state subs override all keywords';
  package bar;
  my $y = if if if;
  is $y, 44, 'state subs from other packages override all keywords';
}
{
  use warnings;
  state $w ;
  local $SIG{__WARN__} = sub { $w .= shift };
  eval '#line 87 squidges
    state sub foo;
    state sub foo {};
  ';
  is $w,
     '"state" subroutine &foo masks earlier declaration in same scope at '
   . "squidges line 88.\n",
     'warning for state sub masking earlier declaration';
}
# Since state vars inside anonymous subs are cloned at the same time as the
# anonymous subs containing them, the same should happen for state subs.
sub make_closure {
  my $x = shift;
  sub {
    state sub foo { $x }
    foo
  }
}
$sub1 = make_closure 48;
$sub2 = make_closure 49;
is &$sub1, 48, 'state sub in closure (1)';
is &$sub2, 49, 'state sub in closure (2)';
# But we need to test that state subs actually do persist from one invoca-
# tion of a named sub to another (i.e., that they are not my subs).
{
  use warnings;
  state $w;
  local $SIG{__WARN__} = sub { $w .= shift };
  eval '#line 65 teetet
    sub foom {
      my $x = shift;
      state sub poom { $x }
      eval{\&poom}
    }
  ';
  is $w, "Variable \"\$x\" will not stay shared at teetet line 67.\n",
         'state subs get "Variable will not stay shared" messages';
  my $poom = foom(27);
  my $poom2 = foom(678);
  is eval{$poom->()}, eval {$poom2->()},
    'state subs close over the first outer my var, like pkg subs';
  my $x = 43;
  for $x (765) {
    state sub etetetet { $x }
    is eval{etetetet}, 43, 'state sub ignores for() localisation';
  }
}
# And we also need to test that multiple state subs can close over each
# other’s entries in the parent subs pad, and that cv_clone is not con-
# fused by that.
sub make_anon_with_state_sub{
  sub {
    state sub s1;
    state sub s2 { \&s1 }
    sub s1 { \&s2 }
    if (@_) { return \&s1 }
    is s1,\&s2, 'state sub in anon closure closing over sibling state sub';
    is s2,\&s1, 'state sub in anon closure closing over sibling state sub';
  }
}
{
  my $s = make_anon_with_state_sub;
  &$s;

  # And make sure the state subs were actually cloned.
  isnt make_anon_with_state_sub->(0), &$s(0),
    'state subs in anon subs are cloned';
  is &$s(0), &$s(0), 'but only when the anon sub is cloned';
}
{
  state sub BEGIN { exit };
  pass 'state subs are never special blocks';
  state sub END { shift }
  is eval{END('jkqeudth')}, jkqeudth,
    'state sub END {shift} implies @_, not @ARGV';
}
{
  state sub redef {}
  use warnings;
  state $w;
  local $SIG{__WARN__} = sub { $w .= shift };
  eval "#line 56 pygpyf\nsub redef {}";
on;
  is $w, "Subroutine redef redefined at pygpyf line 56.\n",
         "sub redefinition warnings from state subs";
}
