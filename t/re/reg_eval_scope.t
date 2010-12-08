#!perl

# Test scoping issues with embedded code in regexps.

BEGIN { chdir 't'; @INC = qw "lib ../lib"; require './test.pl' }

plan 17;

# Functions for turning to-do-ness on and off (as there are so many
# to-do tests) 
sub on { $::TODO = "(?{}) implementation is screwy" }
sub off { undef $::TODO }

on;

fresh_perl_is <<'CODE', '7817', {}, '(?{}) has its own lexical scope';
 my $x = 7; print "a" =~ /(?{ print $x; my $x = 8; print $x; my $y })a/;
 print $x
CODE

fresh_perl_is <<'CODE',
 for my $x("a".."c") {
  $y = 1;
  print scalar
   "abcabc" =~
       /
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
       /x;
  print "$x ";
 }
CODE
 '1a82a93a104a85a96a101a 1b82b93b104b85b96b101b 1c82c93c104c85c96c101c ',
  {},
 'multiple (?{})s in loop with lexicals';

fresh_perl_is <<'CODE', '7817', {}, 'run-time re-eval has its own scope';
 my $x = 7; print "a" =~ /(?{ print $x; my $x = 8; print $x; my $y })a/;
 print $x
CODE

fresh_perl_is <<'CODE', '1782793710478579671017', {},
 use re "eval";
 my $x = 7; $y = 1;
 print scalar
  "abcabc"
    =~ ${\'(?x)
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
       '};
 print $x
CODE
 'multiple (?{})s in "foo" =~ $string';

fresh_perl_is <<'CODE', '1782793710478579671017', {},
 use re "eval";
 my $x = 7; $y = 1;
 print scalar
  "abcabc" =~
      /${\'
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
      '}/x;
 print $x
CODE
 'multiple (?{})s in "foo" =~ /$string/x';

fresh_perl_is <<'CODE', '123123', {},
  for my $x(1..3) {
   push @regexps = qr/(?{ print $x })a/;
  }
 "a" =~ $_ for @regexps;
 "ba" =~ /b$_/ for @regexps;
CODE
 'qr/(?{})/ is a closure';

off;

"a" =~ do { package foo; qr/(?{ $::pack = __PACKAGE__ })a/ };
is $pack, 'foo', 'qr// inherits package';
"a" =~ do { use re "/x"; qr/(?{ $::re = qr-- })a/ };
is $re, '(?^x:)', 'qr// inherits pragmata';

on;

"ba" =~ /b${\do { package baz; qr|(?{ $::pack = __PACKAGE__ })a| }}/;
is $pack, 'baz', '/text$qr/ inherits package';
"ba" =~ m+b${\do { use re "/i"; qr|(?{ $::re = qr-- })a| }}+;
is $re, '(?^i:)', '/text$qr/ inherits pragmata';

off;
{
  use re 'eval';
  package bar;
  "ba" =~ /${\'(?{ $::pack = __PACKAGE__ })a'}/;
}
is $pack, 'bar', '/$text/ containing (?{}) inherits package';
{
  use re 'eval', "/m";
  "ba" =~ /${\'(?{ $::re = qr -- })a'}/;
}
is $re, '(?^m:)', '/$text/ containing (?{}) inherits pragmata';

on;

fresh_perl_is <<'CODE', 'ok', { stderr => 1 }, '(?{die})';
 eval { "a" =~ /(?{die})a/ }; print "ok"
CODE
fresh_perl_is <<'CODE', 'ok', { stderr => 1 }, '(?{last})';
 { "a" =~ /(?{last})a/ }; print "ok"
CODE
fresh_perl_is <<'CODE', 'ok', { stderr => 1 }, '(?{next})';
 { "a" =~ /(?{last})a/ }; print "ok"
CODE
fresh_perl_is <<'CODE', 'ok', { stderr => 1 }, '(?{return})';
 print sub { "a" =~ /(?{return "ok"})a/ }->();
CODE
fresh_perl_is <<'CODE', 'ok', { stderr => 1 }, '(?{goto})';
 "a" =~ /(?{goto _})a/; die; _: print "ok"
CODE
