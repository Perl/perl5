use strict;

package Test::Tester;

# Turn this back on later
#warn "Test::Tester is deprecated, see Test::Stream::Tester\n";

use Test::Stream 1.301001 '-internal';
use Test::Builder 1.301001;
use Test::Stream::Toolset;
use Test::More::Tools;
use Test::Stream qw/-internal STATE_LEGACY/;
use Test::Tester::Capture;

require Exporter;

use vars qw( @ISA @EXPORT $VERSION );

our $VERSION = '1.301001_097';
$VERSION = eval $VERSION;    ## no critic (BuiltinFunctions::ProhibitStringyEval)

@EXPORT  = qw( run_tests check_tests check_test cmp_results show_space );
@ISA     = qw( Exporter );

my $want_space = $ENV{TESTTESTERSPACE};

sub show_space {
    $want_space = 1;
}

my $colour = '';
my $reset  = '';

if (my $want_colour = $ENV{TESTTESTERCOLOUR} || $ENV{TESTTESTERCOLOUR}) {
    if (eval "require Term::ANSIColor") {
        my ($f, $b) = split(",", $want_colour);
        $colour = Term::ANSIColor::color($f) . Term::ANSIColor::color("on_$b");
        $reset  = Term::ANSIColor::color("reset");
    }

}

my $capture = Test::Tester::Capture->new;
sub capture { $capture }

sub find_depth {
    my ($start, $end);
    my $l = 1;
    while (my @call = caller($l++)) {
        $start = $l if $call[3] =~ m/^Test::Builder::(ok|skip|todo_skip)$/;
        next unless $start;
        next unless $call[3] eq 'Test::Tester::run_tests';
        $end = $l;
        last;
    }

    return $Test::Builder::Level + 1 unless defined $start && defined $end;
    # 2 the eval and the anon sub
    return $end - $start - 2;
}

require Test::Stream::Event::Ok;
my $META = Test::Stream::ArrayBase::Meta->get('Test::Stream::Event::Ok');
my $idx = $META->{index} + 1;

sub run_tests {
    my $test = shift;

    my $cstream;
    if ($capture) {
        $cstream = $capture->{stream};
    }

    my ($stream, $old) = Test::Stream->intercept_start($cstream);
    $stream->set_use_legacy(1);
    $stream->state->[-1] = [0, 0, undef, 1];
    $stream->munge(sub {
        my ($stream, $e) = @_;
        $e->[$idx] = find_depth() - $Test::Builder::Level;
        $e->[$idx+1] = $Test::Builder::Level;
        require Carp;
        $e->[$idx + 2] = Carp::longmess();
    });

    my $level = $Test::Builder::Level;

    my @out;
    my $prem = "";

    my $ok = eval {
        $test->();

        for my $e (@{$stream->state->[-1]->[STATE_LEGACY]}) {
            if ($e->isa('Test::Stream::Event::Ok')) {
                push @out => $e->to_legacy;
                $out[-1]->{name} = '' unless defined $out[-1]->{name};
                $out[-1]->{diag} ||= "";
                $out[-1]->{depth} = $e->[$idx];
                for my $d (@{$e->diag || []}) {
                    next if $d->message =~ m{Failed (\(TODO\) )?test (.*\n\s*)?at .* line \d+\.};
                    next if $d->message =~ m{You named your test '.*'\.  You shouldn't use numbers for your test names};
                    chomp(my $msg = $d->message);
                    $msg .= "\n";
                    $out[-1]->{diag} .= $msg;
                }
            }
            elsif ($e->isa('Test::Stream::Event::Diag')) {
                chomp(my $msg = $e->message);
                $msg .= "\n";
                if (!@out) {
                    $prem .= $msg;
                    next;
                }
                next if $msg =~ m{Failed test .*\n\s*at .* line \d+\.};
                $out[-1]->{diag} .= $msg;
            }
        }

        1;
    };
    my $err = $@;

    $stream->state->[-1] = [0, 0, undef, 1];

    Test::Stream->intercept_stop($stream);

    die $err unless $ok;

    return ($prem, @out);
}

sub check_test {
    my $test   = shift;
    my $expect = shift;
    my $name   = shift;
    $name = "" unless defined($name);

    @_ = ($test, [$expect], $name);
    goto &check_tests;
}

sub check_tests {
    my $test    = shift;
    my $expects = shift;
    my $name    = shift;
    $name = "" unless defined($name);

    my ($prem, @results) = eval { run_tests($test, $name) };

    my $ctx = context();

    my $ok = !$@;
    $ctx->ok($ok, "Test '$name' completed");
    $ctx->diag($@) unless $ok;

    $ok = !length($prem);
    $ctx->ok($ok, "Test '$name' no premature diagnostication");
    $ctx->diag("Before any testing anything, your tests said\n$prem") unless $ok;

    cmp_results(\@results, $expects, $name);
    return ($prem, @results);
}

sub cmp_field {
    my ($result, $expect, $field, $desc) = @_;

    my $ctx = context();
    if (defined $expect->{$field}) {
        my ($ok, @diag) = Test::More::Tools->is_eq(
            $result->{$field},
            $expect->{$field},
        );
        $ctx->ok($ok, "$desc compare $field");
    }
}

sub cmp_result {
    my ($result, $expect, $name) = @_;

    my $ctx = context();

    my $sub_name = $result->{name};
    $sub_name = "" unless defined($name);

    my $desc = "subtest '$sub_name' of '$name'";

    {
        cmp_field($result, $expect, "ok", $desc);

        cmp_field($result, $expect, "actual_ok", $desc);

        cmp_field($result, $expect, "type", $desc);

        cmp_field($result, $expect, "reason", $desc);

        cmp_field($result, $expect, "name", $desc);
    }

    # if we got no depth then default to 1
    my $depth = 1;
    if (exists $expect->{depth}) {
        $depth = $expect->{depth};
    }

    # if depth was explicitly undef then don't test it
    if (defined $depth) {
        $ctx->ok(1, "depth checking is deprecated, dummy pass result...");
    }

    if (defined(my $exp = $expect->{diag})) {
        # if there actually is some diag then put a \n on the end if it's not
        # there already

        $exp .= "\n" if (length($exp) and $exp !~ /\n$/);
        my $ok = $result->{diag} eq $exp;
        $ctx->ok(
            $ok,
            "subtest '$sub_name' of '$name' compare diag"
        );
        unless($ok) {
            my $got  = $result->{diag};
            my $glen = length($got);
            my $elen = length($exp);
            for ($got, $exp) {
                my @lines = split("\n", $_);
                $_ = join(
                    "\n",
                    map {
                        if ($want_space) {
                            $_ = $colour . escape($_) . $reset;
                        }
                        else {
                            "'$colour$_$reset'";
                        }
                    } @lines
                );
            }

            $ctx->diag(<<EOM);
Got diag ($glen bytes):
$got
Expected diag ($elen bytes):
$exp
EOM

        }
    }
}

sub escape {
    my $str = shift;
    my $res = '';
    for my $char (split("", $str)) {
        my $c = ord($char);
        if (($c > 32 and $c < 125) or $c == 10) {
            $res .= $char;
        }
        else {
            $res .= sprintf('\x{%x}', $c);
        }
    }
    return $res;
}

sub cmp_results {
    my ($results, $expects, $name) = @_;

    my $ctx = context();

    my ($ok, @diag) = Test::More::Tools->is_num(scalar @$results, scalar @$expects, "Test '$name' result count");
    $ctx->ok($ok, @diag);

    for (my $i = 0; $i < @$expects; $i++) {
        my $expect = $expects->[$i];
        my $result = $results->[$i];

        cmp_result($result, $expect, $name);
    }
}

######## nicked from Test::More
sub import {
    my $class = shift;
    my @plan = @_;

    my $caller = caller;
    my $ctx = context();

    my @imports = ();
    foreach my $idx (0 .. $#plan) {
        if ($plan[$idx] eq 'import') {
            my ($tag, $imports) = splice @plan, $idx, 2;
            @imports = @$imports;
            last;
        }
    }

    my ($directive, $arg) = @plan;
    if ($directive eq 'tests') {
        $ctx->plan($arg);
    }
    elsif ($directive) {
        $ctx->plan(0, $directive, $arg);
    }

    $class->_export_to_level(1, __PACKAGE__, @imports);
}

sub _export_to_level {
    my $pkg   = shift;
    my $level = shift;
    (undef) = shift;    # redundant arg
    my $callpkg = caller($level);
    $pkg->export($callpkg, @_);
}

############

1;

__END__

=head1 NAME

Test::Tester - *DEPRECATED* Ease testing test modules built with Test::Builder

=head1 DEPRECATED

See L<Test::Stream::Tester> for a modern and maintained alternative.

=head1 SYNOPSIS

  use Test::Tester tests => 6;

  use Test::MyStyle;

  check_test(
    sub {
      is_mystyle_eq("this", "that", "not eq");
    },
    {
      ok => 0, # expect this to fail
      name => "not eq",
      diag => "Expected: 'this'\nGot: 'that'",
    }
  );

or

  use Test::Tester;

  use Test::More tests => 3;
  use Test::MyStyle;

  my ($premature, @results) = run_tests(
    sub {
      is_database_alive("dbname");
    }
  );

  # now use Test::More::like to check the diagnostic output

  like($results[0]->{diag}, "/^Database ping took \\d+ seconds$"/, "diag");

=head1 DESCRIPTION

If you have written a test module based on Test::Builder then Test::Tester
allows you to test it with the minimum of effort.

=head1 HOW TO USE (THE EASY WAY)

From version 0.08 Test::Tester no longer requires you to included anything
special in your test modules. All you need to do is

  use Test::Tester;

in your test script B<before> any other Test::Builder based modules and away
you go.

Other modules based on Test::Builder can be used to help with the
testing.  In fact you can even use functions from your module to test
other functions from the same module (while this is possible it is
probably not a good idea, if your module has bugs, then
using it to test itself may give the wrong answers).

The easiest way to test is to do something like

  check_test(
    sub { is_mystyle_eq("this", "that", "not eq") },
    {
      ok => 0, # we expect the test to fail
      name => "not eq",
      diag => "Expected: 'this'\nGot: 'that'",
    }
  );

this will execute the is_mystyle_eq test, capturing it's results and
checking that they are what was expected.

You may need to examine the test results in a more flexible way, for
example, the diagnostic output may be quite long or complex or it may involve
something that you cannot predict in advance like a timestamp. In this case
you can get direct access to the test results:

  my ($premature, @results) = run_tests(
    sub {
      is_database_alive("dbname");
    }
  );

  like($result[0]->{diag}, "/^Database ping took \\d+ seconds$"/, "diag");


We cannot predict how long the database ping will take so we use
Test::More's like() test to check that the diagnostic string is of the right
form.

=head1 HOW TO USE (THE HARD WAY)

I<This is here for backwards compatibility only>

Make your module use the Test::Tester::Capture object instead of the
Test::Builder one. How to do this depends on your module but assuming that
your module holds the Test::Builder object in $Test and that all your test
routines access it through $Test then providing a function something like this

  sub set_builder
  {
    $Test = shift;
  }

should allow your test scripts to do

  Test::YourModule::set_builder(Test::Tester->capture);

and after that any tests inside your module will captured.

=head1 TEST EVENTS

The result of each test is captured in a hash. These hashes are the same as
the hashes returned by Test::Builder->details but with a couple of extra
fields.

These fields are documented in L<Test::Builder> in the details() function

=over 2

=item ok

Did the test pass?

=item actual_ok

Did the test really pass? That is, did the pass come from
Test::Builder->ok() or did it pass because it was a TODO test?

=item name

The name supplied for the test.

=item type

What kind of test? Possibilities include, skip, todo etc. See
L<Test::Builder> for more details.

=item reason

The reason for the skip, todo etc. See L<Test::Builder> for more details.

=back

These fields are exclusive to Test::Tester.

=over 2

=item diag

Any diagnostics that were output for the test. This only includes
diagnostics output B<after> the test result is declared.

Note that Test::Builder ensures that any diagnostics end in a \n and
it in earlier versions of Test::Tester it was essential that you have
the final \n in your expected diagnostics. From version 0.10 onwards,
Test::Tester will add the \n if you forgot it. It will not add a \n if
you are expecting no diagnostics. See below for help tracking down
hard to find space and tab related problems.

=item depth

B<Note:> Depth checking is disabled on newer versions of Test::Builder which no
longer uses $Test::Builder::Level. In these versions this will simple produce a
dummy true result.

This allows you to check that your test module is setting the correct value
for $Test::Builder::Level and thus giving the correct file and line number
when a test fails. It is calculated by looking at caller() and
$Test::Builder::Level. It should count how many subroutines there are before
jumping into the function you are testing. So for example in

  run_tests( sub { my_test_function("a", "b") } );

the depth should be 1 and in

  sub deeper { my_test_function("a", "b") }

  run_tests(sub { deeper() });

depth should be 2, that is 1 for the sub {} and one for deeper(). This
might seem a little complex but if your tests look like the simple
examples in this doc then you don't need to worry as the depth will
always be 1 and that's what Test::Tester expects by default.

B<Note>: if you do not specify a value for depth in check_test() then it
automatically compares it against 1, if you really want to skip the depth
test then pass in undef.

B<Note>: depth will not be correctly calculated for tests that run from a
signal handler or an END block or anywhere else that hides the call stack.

=back

Some of Test::Tester's functions return arrays of these hashes, just
like Test::Builder->details. That is, the hash for the first test will
be array element 1 (not 0). Element 0 will not be a hash it will be a
string which contains any diagnostic output that came before the first
test. This should usually be empty, if it's not, it means something
output diagnostics before any test results showed up.

=head1 SPACES AND TABS

Appearances can be deceptive, especially when it comes to emptiness. If you
are scratching your head trying to work out why Test::Tester is saying that
your diagnostics are wrong when they look perfectly right then the answer is
probably whitespace. From version 0.10 on, Test::Tester surrounds the
expected and got diag values with single quotes to make it easier to spot
trailing whitesapce. So in this example

  # Got diag (5 bytes):
  # 'abcd '
  # Expected diag (4 bytes):
  # 'abcd'

it is quite clear that there is a space at the end of the first string.
Another way to solve this problem is to use colour and inverse video on an
ANSI terminal, see below COLOUR below if you want this.

Unfortunately this is sometimes not enough, neither colour nor quotes will
help you with problems involving tabs, other non-printing characters and
certain kinds of problems inherent in Unicode. To deal with this, you can
switch Test::Tester into a mode whereby all "tricky" characters are shown as
\{xx}. Tricky characters are those with ASCII code less than 33 or higher
than 126. This makes the output more difficult to read but much easier to
find subtle differences between strings. To turn on this mode either call
show_space() in your test script or set the TESTTESTERSPACE environment
variable to be a true value. The example above would then look like

  # Got diag (5 bytes):
  # abcd\x{20}
  # Expected diag (4 bytes):
  # abcd

=head1 COLOUR

If you prefer to use colour as a means of finding tricky whitespace
characters then you can set the TESTTESTCOLOUR environment variable to a
comma separated pair of colours, the first for the foreground, the second
for the background. For example "white,red" will print white text on a red
background. This requires the Term::ANSIColor module. You can specify any
colour that would be acceptable to the Term::ANSIColor::color function.

If you spell colour differently, that's no problem. The TESTTESTERCOLOR
variable also works (if both are set then the British spelling wins out).

=head1 EXPORTED FUNCTIONS

=head2 ($premature, @results) = run_tests(\&test_sub)

\&test_sub is a reference to a subroutine.

run_tests runs the subroutine in $test_sub and captures the results of any
tests inside it. You can run more than 1 test inside this subroutine if you
like.

$premature is a string containing any diagnostic output from before
the first test.

@results is an array of test result hashes.

=head2 cmp_result(\%result, \%expect, $name)

\%result is a ref to a test result hash.

\%expect is a ref to a hash of expected values for the test result.

cmp_result compares the result with the expected values. If any differences
are found it outputs diagnostics. You may leave out any field from the
expected result and cmp_result will not do the comparison of that field.

=head2 cmp_results(\@results, \@expects, $name)

\@results is a ref to an array of test results.

\@expects is a ref to an array of hash refs.

cmp_results checks that the results match the expected results and if any
differences are found it outputs diagnostics. It first checks that the
number of elements in \@results and \@expects is the same. Then it goes
through each result checking it against the expected result as in
cmp_result() above.

=head2 ($premature, @results) = check_tests(\&test_sub, \@expects, $name)

\&test_sub is a reference to a subroutine.

\@expect is a ref to an array of hash refs which are expected test results.

check_tests combines run_tests and cmp_tests into a single call. It also
checks if the tests died at any stage.

It returns the same values as run_tests, so you can further examine the test
results if you need to.

=head2 ($premature, @results) = check_test(\&test_sub, \%expect, $name)

\&test_sub is a reference to a subroutine.

\%expect is a ref to an hash of expected values for the test result.

check_test is a wrapper around check_tests. It combines run_tests and
cmp_tests into a single call, checking if the test died. It assumes
that only a single test is run inside \&test_sub and include a test to
make sure this is true.

It returns the same values as run_tests, so you can further examine the test
results if you need to.

=head2 show_space()

Turn on the escaping of characters as described in the SPACES AND TABS
section.

=head1 HOW IT WORKS

Normally, a test module (let's call it Test:MyStyle) calls
Test::Builder->new to get the Test::Builder object. Test::MyStyle calls
methods on this object to record information about test results. When
Test::Tester is loaded, it replaces Test::Builder's new() method with one
which returns a Test::Tester::Delegate object. Most of the time this object
behaves as the real Test::Builder object. Any methods that are called are
delegated to the real Test::Builder object so everything works perfectly.
However once we go into test mode, the method calls are no longer passed to
the real Test::Builder object, instead they go to the Test::Tester::Capture
object. This object seems exactly like the real Test::Builder object,
except, instead of outputting test results and diagnostics, it just records
all the information for later analysis.

=head1 CAVEATS

Support for calling Test::Builder->note is minimal. It's implemented
as an empty stub, so modules that use it will not crash but the calls
are not recorded for testing purposes like the others. Patches
welcome.

=head1 SEE ALSO

L<Test::Builder> the source of testing goodness. L<Test::Builder::Tester>
for an alternative approach to the problem tackled by Test::Tester -
captures the strings output by Test::Builder. This means you cannot get
separate access to the individual pieces of information and you must predict
B<exactly> what your test will output.

=encoding utf8

=head1 SOURCE

The source code repository for Test::More can be found at
F<http://github.com/Test-More/test-more/>.

=head1 MAINTAINER

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

The following people have all contributed to the Test-More dist (sorted using
VIM's sort function).

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=item Fergal Daly E<lt>fergal@esatclear.ie>E<gt>

=item Mark Fowler E<lt>mark@twoshortplanks.comE<gt>

=item Michael G Schwern E<lt>schwern@pobox.comE<gt>

=item 唐鳳

=back

=head1 COPYRIGHT

There has been a lot of code migration between modules,
here are all the original copyrights together:

=over 4

=item Test::Stream

=item Test::Stream::Tester

Copyright 2014 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::Simple

=item Test::More

=item Test::Builder

Originally authored by Michael G Schwern E<lt>schwern@pobox.comE<gt> with much
inspiration from Joshua Pritikin's Test module and lots of help from Barrie
Slaymaker, Tony Bowden, blackstar.co.uk, chromatic, Fergal Daly and the perl-qa
gang.

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.

Copyright 2001-2008 by Michael G Schwern E<lt>schwern@pobox.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://www.perl.com/perl/misc/Artistic.html>

=item Test::use::ok

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to L<Test-use-ok>.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=item Test::Tester

This module is copyright 2005 Fergal Daly <fergal@esatclear.ie>, some parts
are based on other people's work.

Under the same license as Perl itself

See http://www.perl.com/perl/misc/Artistic.html

=item Test::Builder::Tester

Copyright Mark Fowler E<lt>mark@twoshortplanks.comE<gt> 2002, 2004.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=back
