package Test::More;

use strict;


# Special print function to guard against $\ and -l munging.
sub _print (*@) {
    my($fh, @args) = @_;

    local $\;
    print $fh @args;
}

sub print { die "DON'T USE PRINT!  Use _print instead" }


BEGIN {
    require Test::Simple;
    *TESTOUT = \*Test::Simple::TESTOUT;
    *TESTERR = \*Test::Simple::TESTERR;
}

require Exporter;
use vars qw($VERSION @ISA @EXPORT);
$VERSION = '0.07';
@ISA    = qw(Exporter);
@EXPORT = qw(ok use_ok require_ok
             is isnt like
             skip todo
             pass fail
             eq_array eq_hash eq_set
            );


sub import {
    my($class, $plan, @args) = @_;

    if( $plan eq 'skip_all' ) {
        $Test::Simple::Skip_All = 1;
        _print *TESTOUT, "1..0\n";
        exit(0);
    }
    else {
        Test::Simple->import($plan => @args);
    }

    __PACKAGE__->_export_to_level(1, __PACKAGE__);
}

# 5.004's Exporter doesn't have export_to_level.
sub _export_to_level
{
      my $pkg = shift;
      my $level = shift;
      (undef) = shift;                  # XXX redundant arg
      my $callpkg = caller($level);
      $pkg->export($callpkg, @_);
}


=head1 NAME

Test::More - yet another framework for writing test scripts

=head1 SYNOPSIS

  use Test::More tests => $Num_Tests;
  # or
  use Test::More qw(no_plan);
  # or
  use Test::More qw(skip_all);

  BEGIN { use_ok( 'Some::Module' ); }
  require_ok( 'Some::Module' );

  # Various ways to say "ok"
  ok($this eq $that, $test_name);

  is  ($this, $that,    $test_name);
  isnt($this, $that,    $test_name);
  like($this, qr/that/, $test_name);

  skip {                        # UNIMPLEMENTED!!!
      ok( foo(),       $test_name );
      is( foo(42), 23, $test_name );
  } $how_many, $why;

  todo {                        # UNIMPLEMENTED!!!
      ok( foo(),       $test_name );
      is( foo(42), 23, $test_name );
  } $how_many, $why;

  pass($test_name);
  fail($test_name);

  # Utility comparison functions.
  eq_array(\@this, \@that);
  eq_hash(\%this, \%that);
  eq_set(\@this, \@that);

  # UNIMPLEMENTED!!!
  my @status = Test::More::status;


=head1 DESCRIPTION

If you're just getting started writing tests, have a look at
Test::Simple first.

This module provides a very wide range of testing utilities.  Various
ways to say "ok", facilities to skip tests, test future features
and compare complicated data structures.


=head2 I love it when a plan comes together

Before anything else, you need a testing plan.  This basically declares
how many tests your script is going to run to protect against premature
failure.

The prefered way to do this is to declare a plan when you C<use Test::More>.

  use Test::More tests => $Num_Tests;

There are rare cases when you will not know beforehand how many tests
your script is going to run.  In this case, you can declare that you
have no plan.  (Try to avoid using this as it weakens your test.)

  use Test::More qw(no_plan);

In some cases, you'll want to completely skip an entire testing script.

  use Test::More qw(skip_all);

Your script will declare a skip and exit immediately with a zero
(success).  L<Test::Harness> for details.


=head2 Test names

By convention, each test is assigned a number in order.  This is
largely done automatically for you.  However, its often very useful to
assign a name to each test.  Which would you rather see:

  ok 4
  not ok 5
  ok 6

or

  ok 4 - basic multi-variable
  not ok 5 - simple exponential
  ok 6 - force == mass * acceleration

The later gives you some idea of what failed.  It also makes it easier
to find the test in your script, simply search for "simple
exponential".

All test functions take a name argument.  Its optional, but highly
suggested that you use it.


=head2 I'm ok, you're not ok.

The basic purpose of this module is to print out either "ok #" or "not
ok #" depending on if a given test succeeded or failed.  Everything
else is just gravy.

All of the following print "ok" or "not ok" depending on if the test
succeeded or failed.  They all also return true or false,
respectively.

=over 4

=item B<ok>

  ok($this eq $that, $test_name);

This simply evaluates any expression (C<$this eq $that> is just a
simple example) and uses that to determine if the test succeeded or
failed.  A true expression passes, a false one fails.  Very simple.

For example:

    ok( $exp{9} == 81,                   'simple exponential' );
    ok( Film->can('db_Main'),            'set_db()' );
    ok( $p->tests == 4,                  'saw tests' );
    ok( !grep !defined $_, @items,       'items populated' );

(Mnemonic:  "This is ok.")

$test_name is a very short description of the test that will be printed
out.  It makes it very easy to find a test in your script when it fails
and gives others an idea of your intentions.  $test_name is optional,
but we B<very> strongly encourage its use.

Should an ok() fail, it will produce some diagnostics:

    not ok 18 - sufficient mucus
    #     Failed test 18 (foo.t at line 42)

This is actually Test::Simple's ok() routine.

=cut

# We get ok() from Test::Simple's import().

=item B<is>

=item B<isnt>

  is  ( $this, $that, $test_name );
  isnt( $this, $that, $test_name );

Similar to ok(), is() and isnt() compare their two arguments with
C<eq> and C<ne> respectively and use the result of that to determine
if the test succeeded or failed.  So these:

    # Is the ultimate answer 42?
    is( ultimate_answer(), 42,          "Meaning of Life" );

    # $foo isn't empty
    isnt( $foo, '',     "Got some foo" );

are similar to these:

    ok( ultimate_answer() eq 42,        "Meaning of Life" );
    ok( $foo ne '',     "Got some foo" );

(Mnemonic:  "This is that."  "This isn't that.")

So why use these?  They produce better diagnostics on failure.  ok()
cannot know what you are testing for (beyond the name), but is() and
isnt() know what the test was and why it failed.  For example this
 test:

    my $foo = 'waffle';  my $bar = 'yarblokos';
    is( $foo, $bar,   'Is foo the same as bar?' );

Will produce something like this:

    not ok 17 - Is foo the same as bar?
    #     Failed test 1 (foo.t at line 139)
    #          got: 'waffle'
    #     expected: 'yarblokos'

So you can figure out what went wrong without rerunning the test.

You are encouraged to use is() and isnt() over ok() where possible,
however do not be tempted to use them to find out if something is
true or false!

  # XXX BAD!  $pope->isa('Catholic') eq 1
  is( $pope->isa('Catholic'), 1,        'Is the Pope Catholic?' );

This does not check if C<$pope->isa('Catholic')> is true, it checks if
it returns 1.  Very different.  Similar caveats exist for false and 0.
In these cases, use ok().

  ok( $pope->isa('Catholic') ),         'Is the Pope Catholic?' );

For those grammatical pedants out there, there's an isn't() function
which is an alias of isnt().

=cut

sub is ($$;$) {
    my($this, $that, $name) = @_;

    my $ok = @_ == 3 ? ok($this eq $that, $name)
                     : ok($this eq $that);

    unless( $ok ) {
        _print *TESTERR, <<DIAGNOSTIC;
#          got: '$this'
#     expected: '$that'
DIAGNOSTIC

    }

    return $ok;
}

sub isnt ($$;$) {
    my($this, $that, $name) = @_;

    my $ok = @_ == 3 ? ok($this ne $that, $name)
                     : ok($this ne $that);

    unless( $ok ) {
        _print *TESTERR, <<DIAGNOSTIC;
#     it should not be '$that'
#     but it is.
DIAGNOSTIC

    }

    return $ok;
}

*isn't = \&isnt;


=item B<like>

  like( $this, qr/that/, $test_name );

Similar to ok(), like() matches $this against the regex C<qr/that/>.

So this:

    like($this, qr/that/, 'this is like that');

is similar to:

    ok( $this =~ /that/, 'this is like that');

(Mnemonic "This is like that".)

The second argument is a regular expression.  It may be given as a
regex reference (ie. qr//) or (for better compatibility with older
perls) as a string that looks like a regex (alternative delimiters are
currently not supported):

    like( $this, '/that/', 'this is like that' );

Regex options may be placed on the end (C<'/that/i'>).

Its advantages over ok() are similar to that of is() and isnt().  Better
diagnostics on failure.

=cut

sub like ($$;$) {
    my($this, $regex, $name) = @_;

    my $ok = 0;
    if( ref $regex eq 'Regexp' ) {
        $ok = @_ == 3 ? ok( $this =~ $regex ? 1 : 0, $name )
                      : ok( $this =~ $regex ? 1 : 0 );
    }
    # Check if it looks like '/foo/i'
    elsif( my($re, $opts) = $regex =~ m{^ /(.*)/ (\w*) $ }sx ) {
        $ok = @_ == 3 ? ok( $this =~ /(?$opts)$re/ ? 1 : 0, $name )
                      : ok( $this =~ /(?$opts)$re/ ? 1 : 0 );
    }
    else {
        # Can't use fail() here, the call stack will be fucked.
        my $ok = @_ == 3 ? ok(0, $name )
                         : ok(0);

        _print *TESTERR, <<ERR;
#     '$regex' doesn't look much like a regex to me.  Failing the test.
ERR

        return $ok;
    }

    unless( $ok ) {
        _print *TESTERR, <<DIAGNOSTIC;
#                   '$this'
#     doesn't match '$regex'
DIAGNOSTIC

    }

    return $ok;
}

=item B<pass>

=item B<fail>

  pass($test_name);
  fail($test_name);

Sometimes you just want to say that the tests have passed.  Usually
the case is you've got some complicated condition that is difficult to
wedge into an ok().  In this case, you can simply use pass() (to
declare the test ok) or fail (for not ok).  They are synonyms for
ok(1) and ok(0).

Use these very, very, very sparingly.

=cut

sub pass ($) {
    my($name) = @_;
    return @_ == 1 ? ok(1, $name)
                   : ok(1);
}

sub fail ($) {
    my($name) = @_;
    return @_ == 1 ? ok(0, $name)
                   : ok(0);
}

=back

=head2 Module tests

You usually want to test if the module you're testing loads ok, rather
than just vomiting if its load fails.  For such purposes we have
C<use_ok> and C<require_ok>.

=over 4

=item B<use_ok>

=item B<require_ok>

   BEGIN { use_ok($module); }
   require_ok($module);

These simply use or require the given $module and test to make sure
the load happened ok.  Its recommended that you run use_ok() inside a
BEGIN block so its functions are exported at compile-time and
prototypes are properly honored.

=cut

sub use_ok ($) {
    my($module) = shift;

    my $pack = caller;

    eval <<USE;
package $pack;
require $module;
$module->import;
USE

    my $ok = ok( !$@, "use $module;" );

    unless( $ok ) {
        _print *TESTERR, <<DIAGNOSTIC;
#     Tried to use '$module'.
#     Error:  $@
DIAGNOSTIC

    }

    return $ok;
}


sub require_ok ($) {
    my($module) = shift;

    my $pack = caller;

    eval <<REQUIRE;
package $pack;
require $module;
REQUIRE

    my $ok = ok( !$@, "require $module;" );

    unless( $ok ) {
        _print *TESTERR, <<DIAGNOSTIC;
#     Tried to require '$module'.
#     Error:  $@
DIAGNOSTIC

    }

    return $ok;
}


=head2 Conditional tests

Sometimes running a test under certain conditions will cause the
test script to die.  A certain function or method isn't implemented
(such as fork() on MacOS), some resource isn't available (like a 
net connection) or a module isn't available.  In these cases its
necessary to skip test, or declare that they are supposed to fail
but will work in the future (a todo test).

For more details on skip and todo tests, L<Test::Harness>.

=over 4

=item B<skip>   * UNIMPLEMENTED *

  skip BLOCK $how_many, $why, $if;

B<NOTE> Should that be $if or $unless?

This declares a block of tests to skip, why and under what conditions
to skip them.  An example is the easiest way to illustrate:

    skip {
        ok( head("http://www.foo.com"),     "www.foo.com is alive" );
        ok( head("http://www.foo.com/bar"), "  and has bar" );
    } 2, "LWP::Simple not installed",
    !eval { require LWP::Simple;  LWP::Simple->import;  1 };

The $if condition is optional, but $why is not.

=cut

sub skip {
    die "skip() is UNIMPLEMENTED!";
}

=item B<todo>  * UNIMPLEMENTED *

  todo BLOCK $how_many, $why;
  todo BLOCK $how_many, $why, $until;

Declares a block of tests you expect to fail and why.  Perhaps its
because you haven't fixed a bug:

  todo { is( $Gravitational_Constant, 0 ) }  1,
    "Still tinkering with physics --God";

If you have a set of functionality yet to implement, you can make the
whole suite dependent on that new feature.

  todo {
      $pig->takeoff;
      ok( $pig->altitude > 0 );
      ok( $pig->mach > 2 );
      ok( $pig->serve_peanuts );
  } 1, "Pigs are still safely grounded",
  Pigs->can('fly');

=cut

sub todo {
    die "todo() is UNIMPLEMENTED!";
}

=head2 Comparision functions

Not everything is a simple eq check or regex.  There are times you
need to see if two arrays are equivalent, for instance.  For these
instances, Test::More provides a handful of useful functions.

B<NOTE> These are NOT well-tested on circular references.  Nor am I
quite sure what will happen with filehandles.

=over 4

=item B<eq_array>

  eq_array(\@this, \@that);

Checks if two arrays are equivalent.  This is a deep check, so
multi-level structures are handled correctly.

=cut

#'#
sub eq_array  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;
    return 1 if $a1 eq $a2;

    my $ok = 1;
    for (0..$#{$a1}) {
        my($e1,$e2) = ($a1->[$_], $a2->[$_]);
        $ok = _deep_check($e1,$e2);
        last unless $ok;
    }
    return $ok;
}

sub _deep_check {
    my($e1, $e2) = @_;
    my $ok = 0;

    if($e1 eq $e2) {
        $ok = 1;
    }
    else {
        if( UNIVERSAL::isa($e1, 'ARRAY') and
            UNIVERSAL::isa($e2, 'ARRAY') )
        {
            $ok = eq_array($e1, $e2);
        }
        elsif( UNIVERSAL::isa($e1, 'HASH') and
               UNIVERSAL::isa($e2, 'HASH') )
        {
            $ok = eq_hash($e1, $e2);
        }
        else {
            $ok = 0;
        }
    }
    return $ok;
}


=item B<eq_hash>

  eq_hash(\%this, \%that);

Determines if the two hashes contain the same keys and values.  This
is a deep check.

=cut

sub eq_hash {
    my($a1, $a2) = @_;
    return 0 unless keys %$a1 == keys %$a2;
    return 1 if $a1 eq $a2;

    my $ok = 1;
    foreach my $k (keys %$a1) {
        my($e1, $e2) = ($a1->{$k}, $a2->{$k});
        $ok = _deep_check($e1, $e2);
        last unless $ok;
    }

    return $ok;
}

=item B<eq_set>

  eq_set(\@this, \@that);

Similar to eq_array(), except the order of the elements is B<not>
important.  This is a deep check, but the irrelevancy of order only
applies to the top level.

=cut

# We must make sure that references are treated neutrally.  It really
# doesn't matter how we sort them, as long as both arrays are sorted
# with the same algorithm.
sub _bogus_sort { ref $a ? 0 : $a cmp $b }

sub eq_set  {
    my($a1, $a2) = @_;
    return 0 unless @$a1 == @$a2;

    # There's faster ways to do this, but this is easiest.
    return eq_array( [sort _bogus_sort @$a1], [sort _bogus_sort @$a2] );
}


=back

=head1 BUGS and CAVEATS

The eq_* family have some caveats.

todo() and skip() are unimplemented.

The no_plan feature depends on new Test::Harness feature.  If you're going
to distribute tests that use no_plan your end-users will have to upgrade
Test::Harness to the latest one on CPAN.

=head1 AUTHOR

Michael G Schwern <schwern@pobox.com> with much inspiration from
Joshua Pritikin's Test module and lots of discussion with Barrie
Slaymaker and the perl-qa gang.


=head1 HISTORY

This is a case of convergent evolution with Joshua Pritikin's Test
module.  I was actually largely unware of its existance when I'd first
written my own ok() routines.  This module exists because I can't
figure out how to easily wedge test names into Test's interface (along
with a few other problems).

The goal here is to have a testing utility that's simple to learn,
quick to use and difficult to trip yourself up with while still
providing more flexibility than the existing Test.pm.  As such, the
names of the most common routines are kept tiny, special cases and
magic side-effects are kept to a minimum.  WYSIWYG.


=head1 SEE ALSO

L<Test::Simple> if all this confuses you and you just want to write
some tests.  You can upgrade to Test::More later (its forward
compatible).

L<Test> for a similar testing module.

L<Test::Harness> for details on how your test results are interpreted
by Perl.

L<Test::Unit> describes a very featureful unit testing interface.

L<Pod::Tests> shows the idea of embedded testing.

L<SelfTest> is another approach to embedded testing.

=cut

1;
