package Test::Simple;

use 5.004;

use strict 'vars';
use Test::Utils;

use vars qw($VERSION);

$VERSION = '0.19';

my(@Test_Results) = ();
my($Num_Tests, $Planned_Tests, $Test_Died) = (0,0,0);
my($Have_Plan) = 0;

my $IsVMS = $^O eq 'VMS';


# I'd like to have Test::Simple interfere with the program being
# tested as little as possible.  This includes using Exporter or
# anything else (including strict).
sub import {
    # preserve caller()
    if( @_ > 1 ) {
        if( $_[1] eq 'no_plan' ) {
            goto &no_plan;
        }
        else {
            goto &plan
        }
    }
}

sub plan {
    my($class, %config) = @_;

    if( !exists $config{tests} ) {
        die "You have to tell $class how many tests you plan to run.\n".
            "  use $class tests => 42;  for example.\n";
    }
    elsif( !defined $config{tests} ) {
        die "Got an undefined number of tests.  Looks like you tried to tell ".
            "$class how many tests you plan to run but made a mistake.\n";
    }
    elsif( !$config{tests} ) {
        die "You told $class you plan to run 0 tests!  You've got to run ".
            "something.\n";
    }
    else {
        $Planned_Tests = $config{tests};
    }

    $Have_Plan = 1;

    my_print *TESTOUT, "1..$Planned_Tests\n";

    no strict 'refs';
    my($caller) = caller;
    *{$caller.'::ok'} = \&ok;
    
}


sub no_plan {
    $Have_Plan = 1;

    my($caller) = caller;
    no strict 'refs';
    *{$caller.'::ok'} = \&ok;
}


unless( $^C ) {    
    $| = 1;
    open(*TESTOUT, ">&STDOUT") or _whoa(1, "Can't dup STDOUT!");
    open(*TESTERR, ">&STDOUT") or _whoa(1, "Can't dup STDOUT!");
    {
        my $orig_fh = select TESTOUT;
        $| = 1;
        select TESTERR;
        $| = 1;
        select $orig_fh;
    }
}

=head1 NAME

Test::Simple - Basic utilities for writing tests.

=head1 SYNOPSIS

  use Test::Simple tests => 1;

  ok( $foo eq $bar, 'foo is bar' );


=head1 DESCRIPTION

** If you are unfamiliar with testing B<read Test::Tutorial> first! **

This is an extremely simple, extremely basic module for writing tests
suitable for CPAN modules and other pursuits.  If you wish to do more
complicated testing, use the Test::More module (a drop-in replacement
for this one).

The basic unit of Perl testing is the ok.  For each thing you want to
test your program will print out an "ok" or "not ok" to indicate pass
or fail.  You do this with the ok() function (see below).

The only other constraint is you must predeclare how many tests you
plan to run.  This is in case something goes horribly wrong during the
test and your test program aborts, or skips a test or whatever.  You
do this like so:

    use Test::Simple tests => 23;

You must have a plan.


=over 4

=item B<ok>

  ok( $foo eq $bar, $name );
  ok( $foo eq $bar );

ok() is given an expression (in this case C<$foo eq $bar>).  If its
true, the test passed.  If its false, it didn't.  That's about it.

ok() prints out either "ok" or "not ok" along with a test number (it
keeps track of that for you).

  # This produces "ok 1 - Hell not yet frozen over" (or not ok)
  ok( get_temperature($hell) > 0, 'Hell not yet frozen over' );

If you provide a $name, that will be printed along with the "ok/not
ok" to make it easier to find your test when if fails (just search for
the name).  It also makes it easier for the next guy to understand
what your test is for.  Its highly recommended you use test names.

All tests are run in scalar context.  So this:

    ok( @stuff, 'I have some stuff' );

will do what you mean (fail if stuff is empty)

=cut

sub ok ($;$) {
    my($test, $name) = @_;

    unless( $Have_Plan ) {
        die "You tried to use ok() without a plan!  Gotta have a plan.\n".
            "  use Test::Simple tests => 23;   for example.\n";
    }

    $Num_Tests++;

    my_print *TESTERR, <<ERR if defined $name and $name =~ /^[\d\s]+$/;
You named your test '$name'.  You shouldn't use numbers for your test names.
Very confusing.
ERR


    my($pack, $file, $line) = caller;
    # temporary special case for Test::More & Parrot::Test's calls.
    if( $pack eq 'Test::More' || $pack eq 'Parrot::Test' ) {
        ($pack, $file, $line) = caller(1);
    }

    my($is_todo)  = ${$pack.'::TODO'} ? 1 : 0;

    # We must print this all in one shot or else it will break on VMS
    my $msg;
    unless( $test ) {
        $msg .= "not ";
        $Test_Results[$Num_Tests-1] = $is_todo ? 1 : 0;
    }
    else {
        $Test_Results[$Num_Tests-1] = 1;
    }
    $msg   .= "ok $Num_Tests";

    if( defined $name ) {
        $name =~ s|#|\\#|g;     # # in a name can confuse Test::Harness.
        $msg   .= " - $name";
    }
    if( $is_todo ) {
        my $what_todo = ${$pack.'::TODO'};
        $msg   .= " # TODO $what_todo";
    }
    $msg   .= "\n";

    my_print *TESTOUT, $msg;

    #'#
    unless( $test ) {
        my $msg = $is_todo ? "Failed (TODO)" : "Failed";
        my_print *TESTERR, "#     $msg test ($file at line $line)\n";
    }

    return $test ? 1 : 0;
}


sub _skipped {
    my($why) = shift;

    unless( $Have_Plan ) {
        die "You tried to use ok() without a plan!  Gotta have a plan.\n".
            "  use Test::Simple tests => 23;   for example.\n";
    }

    $Num_Tests++;

    # XXX Set this to "Skip" instead?
    $Test_Results[$Num_Tests-1] = 1;

    # We must print this all in one shot or else it will break on VMS
    my $msg;
    $msg   .= "ok $Num_Tests # skip $why\n";

    my_print *TESTOUT, $msg;

    return 1;
}


=back

Test::Simple will start by printing number of tests run in the form
"1..M" (so "1..5" means you're going to run 5 tests).  This strange
format lets Test::Harness know how many tests you plan on running in
case something goes horribly wrong.

If all your tests passed, Test::Simple will exit with zero (which is
normal).  If anything failed it will exit with how many failed.  If
you run less (or more) tests than you planned, the missing (or extras)
will be considered failures.  If no tests were ever run Test::Simple
will throw a warning and exit with 255.  If the test died, even after
having successfully completed all its tests, it will still be
considered a failure and will exit with 255.

So the exit codes are...

    0                   all tests successful
    255                 test died
    any other number    how many failed (including missing or extras)

If you fail more than 254 tests, it will be reported as 254.

=begin _private

=over 4

=item B<_sanity_check>

  _sanity_check();

Runs a bunch of end of test sanity checks to make sure reality came
through ok.  If anything is wrong it will die with a fairly friendly
error message.

=cut

#'#
sub _sanity_check {
    _whoa($Num_Tests < 0,  'Says here you ran a negative number of tests!');
    _whoa(!$Have_Plan and $Num_Tests, 
          'Somehow your tests ran without a plan!');
    _whoa($Num_Tests != @Test_Results,
          'Somehow you got a different number of results than tests ran!');
}

=item B<_whoa>

  _whoa($check, $description);

A sanity check, similar to assert().  If the $check is true, something
has gone horribly wrong.  It will die with the given $description and
a note to contact the author.

=cut

sub _whoa {
    my($check, $desc) = @_;
    if( $check ) {
        die <<WHOA;
WHOA!  $desc
This should never happen!  Please contact the author immediately!
WHOA
    }
}

=item B<_my_exit>

  _my_exit($exit_num);

Perl seems to have some trouble with exiting inside an END block.  5.005_03
and 5.6.1 both seem to do odd things.  Instead, this function edits $?
directly.  It should ONLY be called from inside an END block.  It
doesn't actually exit, that's your job.

=cut

sub _my_exit {
    $? = $_[0];

    return 1;
}


=back

=end _private

=cut

$SIG{__DIE__} = sub {
    # We don't want to muck with death in an eval, but $^S isn't
    # totally reliable.  5.005_03 and 5.6.1 both do the wrong thing
    # with it.  Instead, we use caller.  This also means it runs under
    # 5.004!
    my $in_eval = 0;
    for( my $stack = 1;  my $sub = (caller($stack))[3];  $stack++ ) {
        $in_eval = 1 if $sub =~ /^\(eval\)/;
    }
    $Test_Died = 1 unless $in_eval;
};

END {
    _sanity_check();

    # Bailout if import() was never called.  This is so
    # "require Test::Simple" doesn't puke.
    do{ _my_exit(0) && return } if !$Have_Plan and !$Num_Tests;

    # Figure out if we passed or failed and print helpful messages.
    if( $Num_Tests ) {
        # The plan?  We have no plan.
        unless( $Planned_Tests ) {
            my_print *TESTOUT, "1..$Num_Tests\n";
            $Planned_Tests = $Num_Tests;
        }

        my $num_failed = grep !$_, @Test_Results[0..$Planned_Tests-1];
        $num_failed += abs($Planned_Tests - @Test_Results);

        if( $Num_Tests < $Planned_Tests ) {
            my_print *TESTERR, <<"FAIL";
# Looks like you planned $Planned_Tests tests but only ran $Num_Tests.
FAIL
        }
        elsif( $Num_Tests > $Planned_Tests ) {
            my $num_extra = $Num_Tests - $Planned_Tests;
            my_print *TESTERR, <<"FAIL";
# Looks like you planned $Planned_Tests tests but ran $num_extra extra.
FAIL
        }
        elsif ( $num_failed ) {
            my_print *TESTERR, <<"FAIL";
# Looks like you failed $num_failed tests of $Planned_Tests.
FAIL
        }

        if( $Test_Died ) {
            my_print *TESTERR, <<"FAIL";
# Looks like your test died just after $Num_Tests.
FAIL

            _my_exit( 255 ) && return;
        }

        _my_exit( $num_failed <= 254 ? $num_failed : 254  ) && return;
    }
    elsif ( $Test::Simple::Skip_All ) {
        _my_exit( 0 ) && return;
    }
    else {
        my_print *TESTERR, "# No tests run!\n";
        _my_exit( 255 ) && return;
    }
}


=pod

This module is by no means trying to be a complete testing system.
Its just to get you started.  Once you're off the ground its
recommended you look at L<Test::More>.


=head1 EXAMPLE

Here's an example of a simple .t file for the fictional Film module.

    use Test::Simple tests => 5;

    use Film;  # What you're testing.

    my $btaste = Film->new({ Title    => 'Bad Taste',
                             Director => 'Peter Jackson',
                             Rating   => 'R',
                             NumExplodingSheep => 1
                           });
    ok( defined($btaste) and ref $btaste eq 'Film',     'new() works' );

    ok( $btaste->Title      eq 'Bad Taste',     'Title() get'    );
    ok( $btaste->Director   eq 'Peter Jackson', 'Director() get' );
    ok( $btaste->Rating     eq 'R',             'Rating() get'   );
    ok( $btaste->NumExplodingSheep == 1,        'NumExplodingSheep() get' );

It will produce output like this:

    1..5
    ok 1 - new() works
    ok 2 - Title() get
    ok 3 - Director() get
    not ok 4 - Rating() get
    #    Failed test (t/film.t at line 14)
    ok 5 - NumExplodingSheep() get
    # Looks like you failed 1 tests of 5

Indicating the Film::Rating() method is broken.


=head1 CAVEATS

Test::Simple will only report a maximum of 254 failures in its exit
code.  If this is a problem, you probably have a huge test script.
Split it into multiple files.  (Otherwise blame the Unix folks for
using an unsigned short integer as the exit status).

Because VMS's exit codes are much, much different than the rest of the
universe, and perl does horrible mangling to them that gets in my way,
it works like this on VMS.

    0     SS$_NORMAL        all tests successful
    4     SS$_ABORT         something went wrong

Unfortunately, I can't differentiate any further.


=head1 NOTES

Test::Simple is B<explicitly> tested all the way back to perl 5.004.


=head1 HISTORY

This module was conceived while talking with Tony Bowden in his
kitchen one night about the problems I was having writing some really
complicated feature into the new Testing module.  He observed that the
main problem is not dealing with these edge cases but that people hate
to write tests B<at all>.  What was needed was a dead simple module
that took all the hard work out of testing and was really, really easy
to learn.  Paul Johnson simultaneously had this idea (unfortunately,
he wasn't in Tony's kitchen).  This is it.


=head1 AUTHOR

Idea by Tony Bowden and Paul Johnson, code by Michael G Schwern
E<lt>schwern@pobox.comE<gt>, wardrobe by Calvin Klein.


=head1 SEE ALSO

=over 4

=item L<Test::More>

More testing functions!  Once you outgrow Test::Simple, look at
Test::More.  Test::Simple is 100% forward compatible with Test::More
(ie. you can just use Test::More instead of Test::Simple in your
programs and things will still work).

=item L<Test>

The original Perl testing module.

=item L<Test::Unit>

Elaborate unit testing.

=item L<Pod::Tests>, L<SelfTest>

Embed tests in your code!

=item L<Test::Harness>

Interprets the output of your test program.

=back

=cut

1;
