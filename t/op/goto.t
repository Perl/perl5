#!./perl

# "This IS structured code.  It's just randomly structured."

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc( qw(. ../lib) );
	require './charset_tools.pl';
}

use warnings;
use strict;
use Config;
plan tests => 95;

our $TODO;

my $deprecated = 0;

local $SIG{__WARN__} = sub {
    if ($_[0] =~ m/jump into a construct.*?, and will become fatal in Perl 5\.42/) {
        $deprecated++;
    }
    else { warn $_[0] }
};

our $foo;
while ($?) {
    $foo = 1;
  label1:
    is($deprecated, 1, "following label1");
    $deprecated = 0;
    $foo = 2;
    goto label2;
} continue {
    $foo = 0;
    goto label4;
  label3:
    is($deprecated, 1, "following label3");
    $deprecated = 0;
    $foo = 4;
    goto label4;
}
is($deprecated, 0, "after 'while' loop");
goto label1;

$foo = 3;

label2:
is($foo, 2, 'escape while loop');
is($deprecated, 0, "following label2");
goto label3;

label4:
is($foo, 4, 'second escape while loop');

my $r = run_perl(prog => 'goto foo;', stderr => 1);
like($r, qr/label/, 'cant find label');

my $thisok = 0;
sub foo {
    goto bar;
    return;
bar:
    $thisok = 1;
}

&foo;
ok($thisok, 'goto in sub');

sub bar {
    my $x = 'bypass';
    eval "goto $x";
}

&bar;
fail('goto bypass');
exit;

FINALE:
is(curr_test(), 11, 'FINALE');

# does goto LABEL handle block contexts correctly?
# note that this scope-hopping differs from last & next,
# which always go up-scope strictly.
my $count = 0;
my $cond = 1;
for (1) {
    if ($cond == 1) {
	$cond = 0;
	goto OTHER;
    }
    elsif ($cond == 0) {
      OTHER:
	$cond = 2;
	is($count, 0, 'OTHER');
	$count++;
	goto THIRD;
    }
    else {
      THIRD:
	is($count, 1, 'THIRD');
	$count++;
    }
}
is($count, 2, 'end of loop');

# Does goto work correctly within a for(;;) loop?
#  (BUG ID 20010309.004 (#5998))

for(my $i=0;!$i++;) {
  my $x=1;
  goto label;
  label: is($x, 1, 'goto inside a for(;;) loop body from inside the body');
}

# Does goto work correctly going *to* a for(;;) loop?
#  (make sure it doesn't skip the initializer)

my ($z, $y) = (0);
FORL1: for ($y=1; $z;) {
    ok($y, 'goto a for(;;) loop, from outside (does initializer)');
    goto TEST19}
($y,$z) = (0, 1);
goto FORL1;

# Even from within the loop?
TEST19: $z = 0;
FORL2: for($y=1; 1;) {
  if ($z) {
    ok($y, 'goto a for(;;) loop, from inside (does initializer)');
    last;
  }
  ($y, $z) = (0, 1);
  goto FORL2;
}

# Does goto work correctly within a try block?
#  (BUG ID 20000313.004) - [perl #2359]
my $ok = 0;
eval {
  my $variable = 1;
  goto LABEL20;
  LABEL20: $ok = 1 if $variable;
};
ok($ok, 'works correctly within a try block');
is($@, "", '...and $@ not set');

# And within an eval-string?
$ok = 0;
eval q{
  my $variable = 1;
  goto LABEL21;
  LABEL21: $ok = 1 if $variable;
};
ok($ok, 'works correctly within an eval string');
is($@, "", '...and $@ still not set');


# Test that goto works in nested eval-string
$ok = 0;
{eval q{
  eval q{
    goto LABEL22;
  };
  $ok = 0;
  last;

  LABEL22: $ok = 1;
};
$ok = 0 if $@;
}
ok($ok, 'works correctly in a nested eval string');

{
    my $false = 0;
    my $count;

    $ok = 0;
    { goto A; A: $ok = 1 } continue { }
    ok($ok, '#20357 goto inside /{ } continue { }/ loop');

    $ok = 0;
    { do { goto A; A: $ok = 1 } while $false }
    ok($ok, '#20154 goto inside /do { } while ()/ loop');
    $ok = 0;
    foreach(1) { goto A; A: $ok = 1 } continue { };
    ok($ok, 'goto inside /foreach () { } continue { }/ loop');

    $ok = 0;
    sub a {
	A: { if ($false) { redo A; B: $ok = 1; redo A; } }
	goto B unless $count++;
    }
    is($deprecated, 0, "before calling sub a()");
    a();
    ok($ok, '#19061 loop label wiped away by goto');
    is($deprecated, 1, "after calling sub a()");
    $deprecated = 0;

    $ok = 0;
    my $p;
    for ($p=1;$p && goto A;$p=0) { A: $ok = 1 }
    ok($ok, 'weird case of goto and for(;;) loop');
    is($deprecated, 1, "following goto and for(;;) loop");
    $deprecated = 0;
}

# bug #22181 - this used to coredump or make $x undefined, due to
# erroneous popping of the inner BLOCK context

undef $ok;
for ($count=0; $count<2; $count++) {
    my $x = 1;
    goto LABEL29;
    LABEL29:
    $ok = $x;
}
is($ok, 1, 'goto in for(;;) with continuation');

# bug #22299 - goto in require doesn't find label

open my $f, ">Op_goto01.pm" or die;
print $f <<'EOT';
package goto01;
goto YYY;
die;
YYY: print "OK\n";
1;
EOT
close $f;

$r = runperl(prog => 'BEGIN { unshift @INC, q[.] } use Op_goto01; print qq[DONE\n]');
is($r, "OK\nDONE\n", "goto within use-d file"); 
unlink_all "Op_goto01.pm";

# test for [perl #24108]
$ok = 1;
$count = 0;
sub i_return_a_label {
    $count++;
    return "returned_label";
}
eval { goto +i_return_a_label; };
$ok = 0;

returned_label:
is($count, 1, 'called i_return_a_label');
ok($ok, 'skipped to returned_label');

goto moretests;
fail('goto moretests');
exit;

bypass:

is(curr_test(), 9, 'eval "goto $x"');

{
    my $wherever = 'NOWHERE';
    eval { goto $wherever };
    like($@, qr/Can't find label NOWHERE/, 'goto NOWHERE sets $@');
}

{
    my $wherever = 'FINALE';
    goto $wherever;
}
fail('goto $wherever');

moretests:
# test goto duplicated labels.
{
    my $z = 0;
    eval {
	$z = 0;
	for (0..1) {
	  L4: # not outer scope
	    $z += 10;
	    last;
	}
	goto L4 if $z == 10;
	last;
    };
    like($@, qr/Can't "goto" into the middle of a foreach loop/,
	    'catch goto middle of foreach');

    $z = 0;
    # ambiguous label resolution (outer scope means endless loop!)
  L1:
    for my $x (0..1) {
	$z += 10;
	is($z, 10, 'prefer same scope (loop body) to outer scope (loop entry)');
	goto L1 unless $x;
	$z += 10;
      L1:
	is($z, 10, 'prefer same scope: second');
	last;
    }

    $z = 0;
  L2: 
    { 
	$z += 10;
	is($z, 10, 'prefer this scope (block body) to outer scope (block entry)');
	goto L2 if $z == 10;
	$z += 10;
      L2:
	is($z, 10, 'prefer this scope: second');
    }


    { 
	$z = 0;
	while (1) {
	  L3: # not inner scope
	    $z += 10;
	    last;
	}
	is($z, 10, 'prefer this scope to inner scope');
	goto L3 if $z == 10;
	$z += 10;
      L3: # this scope !
	is($z, 10, 'prefer this scope to inner scope: second');
    }

  L4: # not outer scope
    { 
	$z = 0;
	while (1) {
	  L4: # not inner scope
	    $z += 1;
	    last;
	}
	is($z, 1, 'prefer this scope to inner,outer scopes');
	goto L4 if $z == 1;
	$z += 10;
      L4: # this scope !
	is($z, 1, 'prefer this scope to inner,outer scopes: second');
    }

    {
	my $loop = 0;
	for my $x (0..1) { 
	  L2: # without this, fails 1 (middle) out of 3 iterations
	    $z = 0;
	  L2: 
	    $z += 10;
	    is($z, 10,
		"same label, multiple times in same scope (choose 1st) $loop");
	    goto L2 if $z == 10 and not $loop++;
	}
    }
}

# This bug was introduced in Aug 2010 by commit ac56e7de46621c6f
# Peephole optimise adjacent pairs of nextstate ops.
# and fixed in Oct 2014 by commit f5b5c2a37af87535
# Simplify double-nextstate optimisation

# The bug manifests as a warning
# Use of "goto" to jump into a construct is deprecated at t/op/goto.t line 442.
# and $out is undefined. Devel::Peek reveals that the lexical in the pad has
# been reset to undef. I infer that pp_goto thinks that it's leaving one scope
# and entering another, but I don't know *why* it thinks that. Whilst this bug
# has been fixed by Father C, because I don't understand why it happened, I am
# not confident that other related bugs remain (or have always existed).

sub DEBUG_TIME() {
    0;
}

{
    if (DEBUG_TIME) {
    }

    {
        my $out = "";
        $out .= 'perl rules';
        goto no_list;
    no_list:
        is($out, 'perl rules', '$out has not been erroneously reset to undef');
    };
}

is($deprecated, 0, 'no warning was emitted');

{
    my $r = runperl(
		stderr => 1,
		prog =>
'for ($_=0;$_<3;$_++){A: if($_==1){next} if($_==2){$_++;goto A}}print qq(ok\n)'
    );
    is($r, "ok\n", 'next and goto');

    $r = runperl(
		stderr => 1,
		prog =>
'for ($_=0;$_<3;$_++){A: if($_==1){$_++;redo} if($_==2){$_++;goto A}}print qq(ok\n)'
    );
    is($r, "ok\n", 'redo and goto');
}

TODO: {
    local $TODO = "[perl #43403] goto() from an if to an else doesn't undo local () changes";
    our $global = "unmodified";
    if ($global) { # true but not constant-folded
         local $global = "modified";
         goto ELSE;
    } else {
         ELSE: is($global, "unmodified");
    }
}

is($deprecated, 0, "following TODOed test for #43403");

#74290
{
    my $x;
    my $y;
    F1:++$x and eval 'return if ++$y == 10; goto F1;';
    is($x, 10,
       'labels outside evals can be distinguished from the start of the eval');
}

goto wham_eth;
die "You can't get here";

wham_eth: 1 if 0;
ouch_eth: pass('labels persist even if their statement is optimised away');

$foo = "(0)";
if($foo eq $foo) {
    goto bungo;
}
$foo .= "(9)";
bungo:
format CHOLET =
wellington
.
$foo .= "(1)";
{
    my $cholet;
    open(CHOLET, ">", \$cholet);
    write CHOLET;
    close CHOLET;
    $foo .= "(".$cholet.")";
    is($foo, "(0)(1)(wellington\n)", "label before format decl");
}

$foo = "(A)";
if($foo eq $foo) {
    goto orinoco;
}
$foo .= "(X)";
orinoco:
sub alderney { return "tobermory"; }
$foo .= "(B)";
$foo .= "(".alderney().")";
is($foo, "(A)(B)(tobermory)", "label before sub decl");

$foo = "[0:".__PACKAGE__."]";
if($foo eq $foo) {
    goto bulgaria;
}
$foo .= "[9]";
bulgaria:
package Tomsk;
$foo .= "[1:".__PACKAGE__."]";
$foo .= "[2:".__PACKAGE__."]";
package main;
$foo .= "[3:".__PACKAGE__."]";
is($foo, "[0:main][1:Tomsk][2:Tomsk][3:main]", "label before package decl");

$foo = "[A:".__PACKAGE__."]";
if($foo eq $foo) {
    goto adelaide;
}
$foo .= "[Z]";
adelaide:
package Cairngorm {
    $foo .= "[B:".__PACKAGE__."]";
}
$foo .= "[C:".__PACKAGE__."]";
is($foo, "[A:main][B:Cairngorm][C:main]", "label before package block");

our $obidos;
$foo = "{0}";
if($foo eq $foo) {
    goto shansi;
}
$foo .= "{9}";
shansi:
BEGIN { $obidos = "x"; }
$foo .= "{1$obidos}";
is($foo, "{0}{1x}", "label before BEGIN block");

$foo = "{A:".(1.5+1.5)."}";
if($foo eq $foo) {
    goto stepney;
}
$foo .= "{Z}";
stepney:
use integer;
$foo .= "{B:".(1.5+1.5)."}";
is($foo, "{A:3}{B:2}", "label before use decl");

$foo = "<0>";
if($foo eq $foo) {
    goto tom;
}
$foo .= "<9>";
tom: dick: harry:
$foo .= "<1>";
$foo .= "<2>";
is($foo, "<0><1><2>", "first of three stacked labels");

$foo = "<A>";
if($foo eq $foo) {
    goto beta;
}
$foo .= "<Z>";
alpha: beta: gamma:
$foo .= "<B>";
$foo .= "<C>";
is($foo, "<A><B><C>", "second of three stacked labels");

$foo = ",0.";
if($foo eq $foo) {
    goto gimel;
}
$foo .= ",9.";
alef: bet: gimel:
$foo .= ",1.";
$foo .= ",2.";
is($foo, ",0.,1.,2.", "third of three stacked labels");

# [perl #112316] Wrong behavior regarding labels with same prefix
sub same_prefix_labels {
    my $pass;
    my $first_time = 1;
    CATCH: {
        if ( $first_time ) {
            CATCHLOOP: {
                if ( !$first_time ) {
                  return 0;
                }
                $first_time--;
                goto CATCH;
            }
        }
        else {
            return 1;
        }
    }
}

ok(
   same_prefix_labels(),
   "perl 112316: goto and labels with the same prefix doesn't get mixed up"
);

eval { my $x = ""; goto $x };
like $@, qr/^goto must have label at /, 'goto $x where $x is empty string';
eval { goto "" };
like $@, qr/^goto must have label at /, 'goto ""';
eval { goto };
like $@, qr/^goto must have label at /, 'argless goto';

eval { my $x = "\0"; goto $x };
like $@, qr/^Can't find label \0 at /, 'goto $x where $x begins with \0';
eval { goto "\0" };
like $@, qr/^Can't find label \0 at /, 'goto "\0"';

TODO: {
  local $::TODO = 'RT #45091: goto in CORE::GLOBAL::exit unsupported';
  fresh_perl_is(<<'EOC', "before\ndie handler\n", {stderr => 1}, 'RT #45091: goto in CORE::GLOBAL::EXIT');
  BEGIN {
    *CORE::GLOBAL::exit = sub {
      goto FASTCGI_NEXT_REQUEST;
    };
  }
  while (1) {
    eval { that_cgi_script() };
    FASTCGI_NEXT_REQUEST:
    last;
  }
  
  sub that_cgi_script {
    local $SIG{__DIE__} = sub { print "die handler\n"; exit; print "exit failed?\n"; };
    print "before\n";
    eval { buggy_code() };
    print "after\n";
  }
  sub buggy_code {
    die "error!";
    print "after die\n";
  }
EOC
}

sub revnumcmp ($$) {
  goto FOO;
  die;
  FOO:
  return $_[1] <=> $_[0];
}
is eval { join(":", sort revnumcmp (9,5,1,3,7)) }, "9:7:5:3:1",
  "can goto at top level of multicalled sub";

# A bit strange, but goingto these constructs should not cause any stack
# problems.  Let’s test them to make sure that is the case.
no warnings 'deprecated';
is \sub :lvalue { goto d; ${*{scalar(do { d: \*foo })}} }->(), \$foo,
   'goto into rv2sv, rv2gv and scalar';
is sub { goto e; $#{; do { e: \@_ } } }->(1..7), 6,
   'goto into $#{...}';
is sub { goto f; prototype \&{; do { f: sub ($) {} } } }->(), '$',
   'goto into srefgen, prototype and rv2cv';
is sub { goto g; ref do { g: [] } }->(), 'ARRAY',
   'goto into ref';
is sub { goto j; defined undef ${; do { j: \(my $foo = "foo") } } }->(),'',
   'goto into defined and undef';
is sub { goto k; study ++${; do { k: \(my $foo = "foo") } } }->(),'1',
   'goto into study and preincrement';
is sub { goto l; ~-!${; do { l: \(my $foo = 0) } }++ }->(),~-1,
   'goto into complement, not, negation and postincrement';
like sub { goto n; sin cos exp log sqrt do { n: 1 } }->(),qr/^0\.51439/,
   'goto into sin, cos, exp, log, and sqrt';
ok sub { goto o; srand do { o: 0 } }->(),
   'goto into srand';
cmp_ok sub { goto p; rand do { p: 1 } }->(), '<', 1,
   'goto into rand';
is sub { goto r; chr ord length int hex oct abs do { r: -15.5 } }->(), 2,
   'goto into chr, ord, length, int, hex, oct and abs';
is sub { goto t; ucfirst lcfirst uc lc do { t: "q" } }->(), 'Q',
   'goto into ucfirst, lcfirst, uc and lc';
{ no strict;
  is sub { goto u; \@{; quotemeta do { u: "." } } }->(), \@{'\.'},
   'goto into rv2av and quotemeta';
}
is join(" ",sub { goto v; %{; do { v: +{1..2} } } }->()), '1 2',
   'goto into rv2hv';
is join(" ",sub { goto w; $_ || do { w: "w" } }->()), 'w',
   'goto into rhs of or';
is join(" ",sub { goto x; $_ && do { x: "w" } }->()), 'w',
   'goto into rhs of and';
is join(" ",sub { goto z; $_ ? do { z: "w" } : 0 }->()), 'w',
   'goto into first leg of ?:';
is join(" ",sub { goto z; $_ ? 0 : do { z: "w" } }->()), 'w',
   'goto into second leg of ?:';
is sub { goto z; caller do { z: 0 } }->(), 'main',
   'goto into caller';
is sub { goto z; exit do { z: return "foo" } }->(), 'foo',
   'goto into exit';
is sub { goto z; eval do { z: "'foo'" } }->(), 'foo',
   'goto into eval';
TODO: {
    local $TODO = "glob() does not currently return a list on VMS" if $^O eq 'VMS';
    is join(",",sub { goto z; glob do { z: "foo bar" } }->()), 'foo,bar',
       'goto into glob';
}
# [perl #132799]
# Erroneous inward goto warning, followed by crash.
# The eval must be in an assignment.
sub _routine {
    my $e = eval {
        goto L2;
      L2:
    }
}
_routine();
pass("bug 132799");

# [perl #132854]
# Goto the *first* parameter of a binary expression, which is harmless.
eval {
    goto __GEN_2;
    my $sent = do {
        __GEN_2:
    };
};
is $@,'', 'goto the first parameter of a binary expression [perl #132854]';

