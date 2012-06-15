#!perl

# Test scoping issues with embedded code in regexps.

BEGIN {
    chdir 't';
    @INC = qw(lib ../lib);
    require './test.pl';
    skip_all_if_miniperl("no dynamic loading on miniperl, no re");
}

plan 34;

fresh_perl_is <<'CODE', '781745', {}, '(?{}) has its own lexical scope';
 my $x = 7; my $a = 4; my $b = 5;
 print "a" =~ /(?{ print $x; my $x = 8; print $x; my $y })a/;
 print $x,$a,$b;
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

fresh_perl_is <<'CODE', '781745', {}, 'run-time re-eval has its own scope';
 use re qw(eval);
 my $x = 7;  my $a = 4; my $b = 5;
 my $rest = 'a';
 print "a" =~ /(?{ print $x; my $x = 8; print $x; my $y })$rest/;
 print $x,$a,$b;
CODE

fresh_perl_is <<'CODE', '178279371047857967101745', {},
 use re "eval";
 my $x = 7; $y = 1;
 my $a = 4; my $b = 5;
 print scalar
  "abcabc"
    =~ ${\'(?x)
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
       '};
 print $x,$a,$b
CODE
 'multiple (?{})s in "foo" =~ $string';

fresh_perl_is <<'CODE', '178279371047857967101745', {},
 use re "eval";
 my $x = 7; $y = 1;
 my $a = 4; my $b = 5;
 print scalar
  "abcabc" =~
      /${\'
        (
         a (?{ print $y; local $y = $y+1; print $x; my $x = 8; print $x })
         b (?{ print $y; local $y = $y+1; print $x; my $x = 9; print $x })
         c (?{ print $y; local $y = $y+1; print $x; my $x = 10; print $x })
        ){2}
      '}/x;
 print $x,$a,$b
CODE
 'multiple (?{})s in "foo" =~ /$string/x';

fresh_perl_is <<'CODE', '123123', {},
  for my $x(1..3) {
   push @regexps, qr/(?{ print $x })a/;
  }
 "a" =~ $_ for @regexps;
 "ba" =~ /b$_/ for @regexps;
CODE
 'qr/(?{})/ is a closure';

"a" =~ do { package foo; qr/(?{ $::pack = __PACKAGE__ })a/ };
is $pack, 'foo', 'qr// inherits package';
"a" =~ do { use re "/x"; qr/(?{ $::re = qr-- })a/ };
is $re, '(?^x:)', 'qr// inherits pragmata';

$::pack = '';
"ba" =~ /b${\do { package baz; qr|(?{ $::pack = __PACKAGE__ })a| }}/;
is $pack, 'baz', '/text$qr/ inherits package';
"ba" =~ m+b${\do { use re "/i"; qr|(?{ $::re = qr-- })a| }}+;
is $re, '(?^i:)', '/text$qr/ inherits pragmata';

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

fresh_perl_is <<'CODE', '45', { stderr => 1 }, '(?{die})';
my $a=4; my $b=5;  eval { "a" =~ /(?{die})a/ }; print $a,$b;
CODE

fresh_perl_is <<'CODE', 'Y45', { stderr => 1 }, '(?{eval{die}})';
my $a=4; my $b=5;
"a" =~ /(?{eval { die; print "X" }; print "Y"; })a/; print $a,$b;
CODE

fresh_perl_is <<'CODE',
    my $a=4; my $b=5;
    sub f { "a" =~ /(?{print((caller(0))[3], "\n");})a/ };
    f();
    print $a,$b;
CODE
    "main::f\n45",
    { stderr => 1 }, 'sub f {(?{caller})}';


fresh_perl_is <<'CODE',
    my $a=4; my $b=5;
    sub f { print ((caller(0))[3], "-", (caller(1))[3], "\n") };
    "a" =~ /(?{f()})a/;
    print $a,$b;
CODE
    "main::f-(unknown)\n45",
    { stderr => 1 }, 'sub f {caller} /(?{f()})/';


fresh_perl_is <<'CODE',
    my $a=4; my $b=5;
    sub f {
	"a" =~ /(?{print "X"; return; print "Y"; })a/;
	print "Z";
    };
    f();
    print $a,$b;
CODE
    "XZ45",
    { stderr => 1 }, 'sub f {(?{return})}';


fresh_perl_is <<'CODE',
my $a=4; my $b=5; "a" =~ /(?{last})a/; print $a,$b
CODE
    q{Can't "last" outside a loop block at - line 1.},
    { stderr => 1 }, '(?{last})';


fresh_perl_is <<'CODE',
my $a=4; my $b=5; "a" =~ /(?{for (1..4) {last}})a/; print $a,$b
CODE
    '45',
    { stderr => 1 }, '(?{for {last}})';


fresh_perl_is <<'CODE',
for (1) {  my $a=4; my $b=5; "a" =~ /(?{last})a/ }; print $a,$b
CODE
    q{Can't "last" outside a loop block at - line 1.},
    { stderr => 1 }, 'for (1) {(?{last})}';


fresh_perl_is <<'CODE',
my $a=4; my $b=5; eval { "a" =~ /(?{last})a/ }; print $a,$b
CODE
    '45',
    { stderr => 1 }, 'eval {(?{last})}';


fresh_perl_is <<'CODE',
my $a=4; my $b=5; "a" =~ /(?{next})a/; print $a,$b
CODE
    q{Can't "next" outside a loop block at - line 1.},
    { stderr => 1 }, '(?{next})';


fresh_perl_is <<'CODE',
my $a=4; my $b=5; "a" =~ /(?{for (1,2,3) { next} })a/; print $a,$b
CODE
    '45',
    { stderr => 1 }, '(?{for {next}})';


fresh_perl_is <<'CODE',
for (1) {  my $a=4; my $b=5; "a" =~ /(?{next})a/ }; print $a,$b
CODE
    q{Can't "next" outside a loop block at - line 1.},
    { stderr => 1 }, 'for (1) {(?{next})}';


fresh_perl_is <<'CODE',
my $a=4; my $b=5; eval { "a" =~ /(?{next})a/ }; print $a,$b
CODE
    '45',
    { stderr => 1 }, 'eval {(?{next})}';


fresh_perl_is <<'CODE',
my $a=4; my $b=5;
"a" =~ /(?{ goto FOO; print "X"; })a/;
print "Y";
FOO:
print $a,$b
CODE
    q{Can't "goto" out of a pseudo block at - line 2.},
    { stderr => 1 }, '{(?{goto})}';


{
    local $::TODO = "goto doesn't yet work in pseduo blocks";
fresh_perl_is <<'CODE',
my $a=4; my $b=5;
"a" =~ /(?{ goto FOO; print "X"; FOO: print "Y"; })a/;
print "Z";
FOO;
print $a,$b
CODE
    "YZ45",
    { stderr => 1 }, '{(?{goto FOO; FOO:})}';
}

# [perl #3590]
fresh_perl_is <<'CODE', '', { stderr => 1 }, '(?{eval{die}})';
"$_$_$_"; my $foo; # these consume pad entries and ensure a SEGV on opd perls
"" =~ m{(?{exit(0)})};
CODE


# [perl #92256]
{ my $y = "a"; $y =~ /a(?{ undef *_ })/ }
pass "undef *_ in a re-eval does not cause a double free";

# make sure regexp warnings are reported on the right line
# (we don't care what warning; the 32768 limit is just one
# that was easy to reproduce) */
{
    use warnings;
    my $w;
    local $SIG{__WARN__} = sub { $w = "@_" };
    my $qr = qr/(??{'a'})/;
    my $filler = 1;
    ("a" x 40_000) =~ /^$qr(ab*)+/; my $line = __LINE__;
    like($w, qr/recursion limit.* line $line\b/, "warning on right line");
}

# on immediate exit from pattern with code blocks, make sure PL_curcop is
# restored

{
    use re 'eval';

    my $c = '(?{"1"})';
    my $w = '';
    my $l;

    local $SIG{__WARN__} = sub { $w .= "@_" };
    $l = __LINE__; "1" =~ /^1$c/x and warn "foo";
    like($w, qr/foo.+line $l/, 'curcop 1');

    $w = '';
    $l = __LINE__; "4" =~ /^1$c/x or warn "foo";
    like($w, qr/foo.+line $l/, 'curcop 2');

    $c = '(??{"1"})';
    $l = __LINE__; "1" =~ /^$c/x and warn "foo";
    like($w, qr/foo.+line $l/, 'curcop 3');

    $w = '';
    $l = __LINE__; "4" =~ /^$c/x or warn "foo";
    like($w, qr/foo.+line $l/, 'curcop 4');
}
