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
plan tests =>  87;

our $TODO;

our $foo;
while ($?) {
    $foo = 1;
  label1:
    $foo = 2;
    goto label2;
}
continue {
    $foo = 0;
    goto label4;
  label3:
    $foo = 4;
    goto label4;
}

$foo = 3;

label2:
is($foo, 3, 'escape while loop');

label4:
is($foo, 3, 'second escape while loop');

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
pass('goto bypass');

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
    goto TEST19
}
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

# Does goto work correctly within a eval block?
#  (BUG ID 20000313.004) - [perl #2359]
my $ok = 0;
eval {
    my $variable = 1;
    goto LABEL20;
    LABEL20: $ok = 1 if $variable;
};
ok($ok, 'works correctly within a eval block');
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
{
    eval q{
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
    }
    a();

    $ok = 0;
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

{
    # test of "computed 'goto'"
    my $wherever = 'NOWHERE';
    eval { goto $wherever };
    like($@, qr/Can't find label NOWHERE/, 'goto NOWHERE sets $@');
}

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

{
    # tests of __PACKAGE__ syntax:
    # 2 tests moved from t/comp/package_block.t and modified to use inline
    # package syntax

    $main::result = "";
    $main::warning = "";
    $SIG{__WARN__} = sub { $main::warning .= $_[0]; };
    eval q{
        $main::result .= "a(".__PACKAGE__."/".eval("__PACKAGE__").")";
        goto l0;
        $main::result .= "b(".__PACKAGE__."/".eval("__PACKAGE__").")";

        package Foo;
        $main::result .= "c(".__PACKAGE__."/".eval("__PACKAGE__").")";
        l0:
            $main::result .= "d(".__PACKAGE__."/".eval("__PACKAGE__").")";
            goto l1;
        $main::result .= "e(".__PACKAGE__."/".eval("__PACKAGE__").")";

        package main;
        $main::result .= "f(".__PACKAGE__."/".eval("__PACKAGE__").")";
        l1:
            $main::result .= "g(".__PACKAGE__."/".eval("__PACKAGE__").")";
            goto l2;
        $main::result .= "h(".__PACKAGE__."/".eval("__PACKAGE__").")";

        package Bar;
        l2:
            $main::result .= "i(".__PACKAGE__."/".eval("__PACKAGE__").")";

        package main;
        $main::result .= "j(".__PACKAGE__."/".eval("__PACKAGE__").")";
    };
    my $expected = 'a(main/main)d(Foo/Foo)g(main/main)i(Bar/Bar)j(main/main)';
    is($main::result, $expected, "Got expected");
    ok(! $main::warning, "Jumping into labels in different packages ran without warnings");
}

# [GH #23806]
{
    my $x = "good";
    goto("GH23806") . "skip";
    GH23806: $x = "bad";
    GH23806skip:
    is $x, "good", "goto EXPR exempt from 'looks like a function' rule";
}

# [GH #23810]
{
    local $@;
    eval {
        goto GH23810;
        if (0) {
            GH23810: ;
        }
    };
    like($@, qr/^Can't find label GH23810/,
        "goto LABEL can't be used to go into a construct that is optimized away");
}

note("Tests of functionality fatalized in Perl 5.44");
my $msg = q|Use of "goto" to jump into a construct is no longer permitted|;

{

    local $@;
    my $false = 0;
    my $thisok = 0;

    eval {
        for (my $p=1; $p && goto A; $p=0) {
            A: $thisok = 1;
        }
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: following goto and for(;;) loop');

    eval {
        no warnings 'void';
        \sub :lvalue { goto d; ${*{scalar(do { d: \*foo })}} }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into rv2sv, rv2gv and scalar');

    eval {
        sub { goto e; $#{; do { e: \@_ } } }->(1..7);
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into $#{...}');

    eval {
        sub { goto f; prototype \&{; do { f: sub ($) {} } } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into srefgen, prototype and rv2cv');

    eval {
        sub { goto g; ref do { g: [] } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into ref');

    eval {
        sub { goto j; defined undef ${; do { j: \(my $foo = "foo") } } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into defined and undef');

    eval {
        sub { goto k; study ++${; do { k: \(my $foo = "foo") } } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into study and preincrement');

    eval {
        sub { goto l; ~-!${; do { l: \(my $foo = 0) } }++ }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into complement, not, negation and postincrement');

    eval {
        sub { goto n; sin cos exp log sqrt do { n: 1 } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into sin, cos, exp, log, and sqrt');

    eval {
        sub { goto o; srand do { o: 0 } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into srand');

    eval {
        sub { goto p; rand do { p: 1 } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into rand');

    eval {
        sub { goto r; chr ord length int hex oct abs do { r: -15.5 } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into chr, ord, length, int, hex, oct and abs');

    eval {
        sub { goto t; ucfirst lcfirst uc lc do { t: "q" } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into ucfirst, lcfirst, uc and lc');

    eval {
        sub { goto u; \@{; quotemeta do { u: "." } } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into rv2av and quotemeta');

    eval {
        no warnings 'void';
        join(" ",sub { goto v; %{; do { v: +{1..2} } } }->());
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into rv2hv');

    eval {
        no warnings 'void';
        join(" ",sub { goto w; $_ || do { w: "w" } }->());
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into rhs of or');

    eval {
        no warnings 'void';
        join(" ",sub { goto x; $_ && do { x: "w" } }->());
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into rhs of and');

    eval {
        no warnings 'void';
        join(" ",sub { goto z; $_ ? do { z: "w" } : 0 }->());
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into first leg of ?:');

    eval {
        no warnings 'void';
        join(" ",sub { goto z; $_ ? 0 : do { z: "w" } }->());
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into second leg of ?:');

    eval {
        sub { goto z; caller do { z: 0 } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into caller');

    eval {
        sub { goto z; exit do { z: return "foo" } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into exit');

    eval {
        sub { goto z; eval do { z: "'foo'" } }->();
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into eval');

    eval {
        no warnings 'void';
        join(",",sub { goto z; glob do { z: "foo bar" } }->());
    };
    like($@, qr/$msg/,
        'Got expected exception; formerly: goto into glob');

}

