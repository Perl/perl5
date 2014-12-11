use strict;
use warnings;

use Test::Stream;
use Test::More;
use Scalar::Util qw/blessed/;

# This will replace the main Test::Stream object for the scope of the coderef.
# We apply our output changes only in that scope so that this test itself can
# verify things with regular TAP output. The things done inside thise sub would
# work just fine when used by any module to alter the output.

my @OUTPUT;
Test::Stream->intercept(sub {
    # Turn off normal TAP output
    Test::Stream->shared->set_use_tap(0);

    # Turn off legacy storage of results.
    Test::Stream->shared->set_use_legacy(0);

    Test::Stream->shared->listen(sub {
        my ($stream, $event) = @_;

        push @OUTPUT => "We got an event of type " . blessed($event);
    });

    # Now we run some tests, no TAP will be produced, instead all events will
    # be added to @OUTPUT.

    ok(1, "pass");
    ok(0, "fail");

    subtest foo => sub {
        ok(1, "pass");
        ok(0, "fail");
    };

    diag "Hello";
});

is_deeply(
    \@OUTPUT,
    [
        'We got an event of type Test::Stream::Event::Ok',
        'We got an event of type Test::Stream::Event::Ok',
        'We got an event of type Test::Stream::Event::Note',
        'We got an event of type Test::Stream::Event::Subtest',
        'We got an event of type Test::Stream::Event::Diag',
    ],
    "Got all events"
);

# Now for something more complicated, lets have everything be normal TAP,
# except subtests

my (@STDOUT, @STDERR, @TODO);
my @IO = (\@STDOUT, \@STDERR, \@TODO);

Test::Stream->intercept(sub {
    # Turn off normal TAP output
    Test::Stream->shared->set_use_tap(0);

    # Turn off legacy storage of results.
    Test::Stream->shared->set_use_legacy(0);

    my $number = 1;
    Test::Stream->shared->listen(sub {
        my ($stream, $e) = @_;

        # Do not output results inside subtests
        return if $e->in_subtest;

        return unless $e->can('to_tap');

        my $num = $stream->use_numbers ? $number++ : undef;

        # Get the TAP for the event
        my @sets;
        if ($e->isa('Test::Stream::Event::Subtest')) {
            # Subtest is a subclass of Ok, use Ok's to_tap method:
            @sets = Test::Stream::Event::Ok::to_tap($e, $num);
            # Here you can also add whatever output you want.
        }
        else {
            @sets = $e->to_tap($num);
        }

        for my $set (@sets) {
            my ($hid, $msg) = @$set;
            next unless $msg;
            my $enc = $e->encoding || die "Could not find encoding!";

            # This is how you get the proper handle to use (STDERR, STDOUT, ETC).
            my $io = $stream->io_sets->{$enc}->[$hid] || die "Could not find IO $hid for $enc";
            $io = $IO[$hid];

            # Make sure we don't alter these vars.
            local($\, $", $,) = (undef, ' ', '');

            # Normally you print to the IO, but here we are pushing to arrays
            chomp($msg);
            push @$io => $msg;
        }
    });

    # Now we run some tests, no TAP will be produced, instead all events will
    # be added to our ourputs

    ok(1, "pass");
    ok(0, "fail");

    subtest foo => sub {
        ok(1, "pass");
        ok(0, "fail");
    };

    diag "Hello";
});

is(@TODO, 0, "No TODO output");

is_deeply(
    \@STDOUT,
    [
        'ok 1 - pass',
        'not ok 2 - fail',
        '# Subtest: foo',
        # As planned, none of the events inside the subtest got rendered.
        'not ok 4 - foo'
    ],
    "Got expected TAP"
);

is(pop(@STDERR), "# Hello", "Got the hello diag");
is(@STDERR, 2, "got diag for 2 failed tests");

done_testing;
