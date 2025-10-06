#!./perl

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc( qw(. ../lib) );
	require './charset_tools.pl';
}

use v5.16;
use warnings;
use Config;
plan tests => 44;

# Excerpts from 'perldoc -f goto' as of perl-5.40.1 (Aug 2025)
#
# The "goto &NAME" form is quite different from the other forms of
# "goto". In fact, it isn't a goto in the normal sense at all, and
# doesn't have the stigma associated with other gotos. Instead, it
# exits the current subroutine (losing any changes set by "local")
# and immediately calls in its place the named subroutine using
# the current value of @_. This is used by "AUTOLOAD" subroutines
# that wish to load another subroutine and then pretend that the
# other subroutine had been called in the first place (except that
# any modifications to @_ in the current subroutine are propagated
# to the other subroutine.) After the "goto", not even "caller"
# will be able to tell that this routine was called first.
#
# NAME needn't be the name of a subroutine; it can be a scalar
# variable containing a code reference or a block that evaluates
# to a code reference.

# but earlier, we see:
#
# The "goto EXPR" form expects to evaluate "EXPR" to a code
# reference or a label name. If it evaluates to a code reference,
# it will be handled like "goto &NAME", below. This is especially
# useful for implementing tail recursion via "goto __SUB__".
#
# The purpose this test file is to consolidate all tests formerly found in
# t/op/goto.t that exercise the "goto &NAME" functionality.  These should be
# outside the scope of the current (5.42) deprecation of aspects of "goto
# LABEL" (GH #23618) now scheduled for 5.44.  If we have done that
# successfully, then during the 5.43 dev cycle we shouldn't see any instances
# of this warning (or of its fatalization replacement).

my $deprecated = 0;

local $SIG{__WARN__} = sub {
    if ($_[0] =~ m/jump into a construct.*?, and will become fatal in Perl 5\.42/) {
        $deprecated++;
    }
    else { warn $_[0] }
};

our $foo;

###################

# bug #9990 - don't prematurely free the CV we're &going to.

sub f1 {
    my $x;
    goto sub { $x=0; ok(1, "don't prematurely free CV"); };
}
f1();

# bug #99850, which is similar - freeing the subroutine we are about to
# go(in)to during a FREETMPS call should not crash perl.

package _99850 {
    sub reftype{}
    DESTROY { undef &reftype }
    eval { sub { my $guard = bless []; goto &reftype }->() };
}
like $@, qr/^Goto undefined subroutine &_99850::reftype at /,
   'goto &foo undefining &foo on sub cleanup';

# When croaking after discovering that the new CV you're about to goto is
# undef, make sure that the old CV isn't doubly freed.

package Do_undef {
    my $count;

    # creating a new closure here encourages any prematurely freed
    # CV to be reallocated
    sub DESTROY { undef &undef_sub; my $x = sub { $count } }

    sub f {
        $count++;
        my $guard = bless []; # trigger DESTROY during goto
        *undef_sub = sub {};
        goto &undef_sub
    }

    for (1..10) {
        eval { f() };
    }
    ::is($count, 10, "goto undef_sub safe");
}

# make sure that nothing nasty happens if the old CV is freed while
# goto'ing

package Free_cv {
    my $results;
    sub f {
        no warnings 'redefine';
        *f = sub {};
        goto &g;
    }
    sub g { $results = "(@_)" }

    f(1,2,3);
    ::is($results, "(1 2 3)", "Free_cv");
}

# [perl #29708] - goto &foo could leave foo() at depth two with
# @_ == PL_sv_undef, causing a coredump

my $r = runperl(
    prog =>
	'sub f { return if $d; $d=1; my $a=sub {goto &f}; &$a; f() } f(); print qq(ok\n)',
    stderr => 1
    );
is($r, "ok\n", 'avoid pad without an @_');

# see if a modified @_ propagates
{
  my $i;
  package Foo;
  sub DESTROY	{ my $s = shift; ::is($s->[0], $i, "destroy $i"); }
  sub show	{ ::is(+@_, 5, "show $i",); }
  sub start	{ push @_, 1, "foo", {}; goto &show; }
  for (1..3)	{ $i = $_; start(bless([$_]), 'bar'); }
}

sub auto {
    goto &loadit;
}
my $ok;

sub AUTOLOAD { $ok = 1 if "@_" eq "foo" }

$ok = 0;
auto("foo");
ok($ok, 'autoload');

# Test autoloading mechanism.

sub two {
    my ($pack, $file, $line) = caller;	# Should indicate original call stats.
    is("@_ $pack $file $line", "1 2 3 main $::FILE $::LINE",
	'autoloading mechanism.');
}

sub one {
    eval <<'END';
    no warnings 'redefine';
    sub one { pass('sub one'); goto &two; fail('sub one tail'); }
END
    goto &one;
}

$::FILE = __FILE__;
$::LINE = __LINE__ + 1;
&one(1,2,3);

# deep recursion with gotos eventually caused a stack reallocation
# which messed up buggy internals that didn't expect the stack to move

sub recurse1 {
    unshift @_, "x";
    no warnings 'recursion';
    goto &recurse2;
}
sub recurse2 {
    my $x = shift;
    $_[0] ? +1 + recurse1($_[0] - 1) : 0
}

{
my $w = 0;
    local $SIG{__WARN__} = sub { ++$w };
    is(recurse1(500), 500, 'recursive goto &foo');
    is $w, 0, 'no recursion warnings for "no warnings; goto &sub"';
    delete $SIG{__WARN__};
}

# [perl #32039] Chained goto &sub drops data too early.

sub a32039 { @_=("foo"); goto &b32039; }
sub b32039 { goto &c32039; }
sub c32039 { is($_[0], 'foo', 'chained &goto') }
a32039();

###################

# goto &foo not allowed in evals

sub null { 1 };
eval 'goto &null';
like($@, qr/Can't goto subroutine from an eval-string/, 'eval string');
eval { goto &null };
like($@, qr/Can't goto subroutine from an eval-block/, 'eval block');

# goto &foo leaves @_ alone when called from a sub
sub returnarg { $_[0] };
is sub {
    local *_ = ["ick and queasy"];
    goto &returnarg;
}->("quick and easy"), "ick and queasy",
  'goto &foo with *_{ARRAY} replaced';
my @__ = byte_utf8a_to_utf8n("\xc4\x80");
sub { local *_ = \@__; goto &utf8::decode }->("no thinking aloud");
is "@__", chr 256, 'goto &xsub with replaced *_{ARRAY}';

# And goto &foo should leave reified @_ alone
sub { *__ = \@_;  goto &null } -> ("rough and tubbery");
is ${*__}[0], 'rough and tubbery', 'goto &foo leaves reified @_ alone';

# goto &xsub when @_ has nonexistent elements
{
    no warnings "uninitialized";
    local @_ = ();
    $#_++;
    & {sub { goto &utf8::encode }};
    is @_, 1, 'num of elems in @_ after goto &xsub with nonexistent $_[0]';
    is $_[0], "", 'content of nonexistent $_[0] is modified by goto &xsub';
}

# goto &xsub when @_ itself does not exist
undef *_;
eval { & { sub { goto &utf8::encode } } };
# The main thing we are testing is that it did not crash.  But make sure 
# *_{ARRAY} was untouched, too.
is *_{ARRAY}, undef, 'goto &xsub when @_ does not exist';

# goto &perlsub when @_ itself does not exist [perl #119949]
# This was only crashing when the replaced sub call had an argument list.
# (I.e., &{ sub { goto ... } } did not crash.)
sub {
    undef *_;
    goto sub {
	is *_{ARRAY}, undef, 'goto &perlsub when @_ does not exist';
    }
}->();
sub {
    local *_;
    goto sub {
	is *_{ARRAY}, undef, 'goto &sub when @_ does not exist (local *_)';
    }
}->();

# [perl #36521] goto &foo in warn handler could defeat recursion avoider

{
    my $r = runperl(
		stderr => 1,
		prog => 'my $d; my $w = sub { return if $d++; warn q(bar)}; local $SIG{__WARN__} = sub { goto &$w; }; warn q(foo);'
    );
    like($r, qr/bar/, "goto &foo in warn");
}

{
    sub TIESCALAR { bless [pop] }
    sub FETCH     { $_[0][0] }
    tie my $t, "", sub { "cluck up porridge" };
    is eval { sub { goto $t }->() }//$@, 'cluck up porridge',
      'tied arg returning sub ref';
}

# v5.31.3-198-gd2cd363728 broke this. goto &XS_sub  wasn't restoring
# cx->blk_sub.old_cxsubix. Would panic in pp_return

{
    # isa is an XS sub
    sub g198 {  goto &UNIVERSAL::isa }

    sub f198 {
        g198([], 1 );
        {
            return 1;
        }
    }
    eval { f198(); };
    is $@, "", "v5.31.3-198-gd2cd363728";
}

# GH #19188
#
# 'goto &xs_sub' should provide the correct caller context to an XS sub

SKIP:
{
    skip "No XS::APItest in miniperl", 6 if is_miniperl();
    skip "No XS::APItest in static perl", 6 if not $Config{usedl};

    require XS::APItest;

    sub f_19188 { goto &XS::APItest::gimme }
    sub g_19188{ f_19188(); }
    my ($s, @a);

    f_19188();
    is ($XS::APItest::GIMME_V, 1, 'xs_goto void (#19188)');

    $s = f_19188();
    is ($XS::APItest::GIMME_V, 2, 'xs_goto scalar (#19188)');

    @a = f_19188();
    is ($XS::APItest::GIMME_V, 3, 'xs_goto list (#19188)');

    g_19188();
    is ($XS::APItest::GIMME_V, 1, 'xs_goto indirect void (#19188)');

    $s = g_19188();
    is ($XS::APItest::GIMME_V, 2, 'xs_goto indirect scalar (#19188)');

    @a = g_19188();
    is ($XS::APItest::GIMME_V, 3, 'xs_goto indirect list (#19188)');
}

# GH #19936 segfault on goto &xs_sub when calling sub is replaced
SKIP:
{
    skip "No XS::APItest in miniperl", 2 if is_miniperl();
    skip "No XS::APItest in static perl", 2 if not $Config{usedl};

    # utf8::is_utf8() is just an example of an XS sub
    sub foo_19936 { *foo_19936 = {}; goto &utf8::is_utf8 }
    ok(foo_19936("\x{100}"), "GH #19936 utf8 XS call");

    # the gimme XS function accesses PL_op, which was null before the fix
    sub bar_19936 { *bar_19936 = {}; goto &XS::APItest::gimme }
    my @a = bar_19936();
    is($XS::APItest::GIMME_V, 3, "GH #19936 gimme XS call");
}

# goto &sub could leave AvARRAY() slots of @_ uninitialised.

{
    my $i = 0;
    my $f = sub {
        goto &{ sub {} } unless $i++;
        $_[1] = 1; # create a hole
        # accessing $_[0] is more for valgrind/ASAN to chew on rather than
        # we're too concerned about its value. Or it might give "bizarre
        # copy" errors.
        is($_[0], undef, "goto and AvARRAY");
    };

    # first call does goto, which gives &$f a fresh AV in pad[0],
    # which formerly allocated an AvARRAY for it, but didn't zero it
    $f->();
    # second call creates hole in @_ which used to to be a wild SV pointer
    $f->();
}


# GH 23804 goto __SUB__
{
    my $fac = sub {
        unshift @_, 1;
        goto sub {
            my ($acc, $i) = @_;
            return $acc if $i < 2;
            @_ = ($acc * $i, $i - 1);
            goto __SUB__;
        };
    };

    is $fac->(5), 120, 'recursion via goto __SUB__';
}

# GH 23811 goto &NAME where block evaluates to coderef
{
    local $@;
    my $hw = 'hello world';

    eval {
        my $coderef = sub { return $hw; };
        my $rv = goto &{ 1; $coderef; };
    };
    like($@, qr/^Can't goto subroutine from an eval-block/,
        "Can't goto subroutine (block which evaluates to coderef) from an eval block");

    eval {
        sub helloworld { return $hw; }
        my $rv = goto &helloworld;
    };
    like($@, qr/^Can't goto subroutine from an eval-block/,
        "Can't goto named subroutine from an eval block");

    eval {
        my $coderef = sub { return $hw; };
        my $rv = goto &$coderef;
    };
    like($@, qr/^Can't goto subroutine from an eval-block/,
        "Can't goto subroutine (&coderef) from an eval block");
}

# Final test: ensure that we saw no deprecation warnings
# ... but rework this to count fatalizations once work is more developed

is($deprecated, 0, "No 'jump into a construct' warnings seen");
