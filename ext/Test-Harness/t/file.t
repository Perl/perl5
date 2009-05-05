#!/usr/bin/perl -w

BEGIN {
    if ( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ( '../lib', '../ext/Test-Harness/t/lib' );
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More;

use TAP::Harness;

my $HARNESS = 'TAP::Harness';

my $source_tests
  = $ENV{PERL_CORE} ? '../ext/Test-Harness/t/source_tests' : 't/source_tests';
my $sample_tests
  = $ENV{PERL_CORE} ? '../ext/Test-Harness/t/sample-tests' : 't/sample-tests';

plan tests => 41;

# note that this test will always pass when run through 'prove'
ok $ENV{HARNESS_ACTIVE},  'HARNESS_ACTIVE env variable should be set';
ok $ENV{HARNESS_VERSION}, 'HARNESS_VERSION env variable should be set';

{
    my @output;
    local $^W;
    require TAP::Formatter::Base;
    local *TAP::Formatter::Base::_output = sub {
        my $self = shift;
        push @output => grep { $_ ne '' }
          map {
            local $_ = $_;
            chomp;
            trim($_)
          } map { split /\n/ } @_;
    };
    my $harness            = TAP::Harness->new( { verbosity  => 1 } );
    my $harness_whisper    = TAP::Harness->new( { verbosity  => -1 } );
    my $harness_mute       = TAP::Harness->new( { verbosity  => -2 } );
    my $harness_directives = TAP::Harness->new( { directives => 1 } );
    my $harness_failures   = TAP::Harness->new( { failures   => 1 } );

    can_ok $harness, 'runtests';

    # normal tests in verbose mode

    ok my $aggregate = _runtests( $harness, "$source_tests/harness" ),
      '... runtests returns the aggregate';

    isa_ok $aggregate, 'TAP::Parser::Aggregator';

    chomp(@output);

    my @expected = (
        "$source_tests/harness ..",
        '1..1',
        'ok 1 - this is a test',
        'ok',
        'All tests successful.',
    );
    my $status           = pop @output;
    my $expected_status  = qr{^Result: PASS$};
    my $summary          = pop @output;
    my $expected_summary = qr{^Files=1, Tests=1,  \d+ wallclock secs};

    is_deeply \@output, \@expected, '... and the output should be correct';
    like $status, $expected_status,
      '... and the status line should be correct';
    like $summary, $expected_summary,
      '... and the report summary should look correct';

    # use an alias for test name

    @output = ();
    ok $aggregate
      = _runtests( $harness, [ "$source_tests/harness", 'My Nice Test' ] ),
      '... runtests returns the aggregate';

    isa_ok $aggregate, 'TAP::Parser::Aggregator';

    chomp(@output);

    @expected = (
        'My Nice Test ..',
        '1..1',
        'ok 1 - this is a test',
        'ok',
        'All tests successful.',
    );
    $status           = pop @output;
    $expected_status  = qr{^Result: PASS$};
    $summary          = pop @output;
    $expected_summary = qr{^Files=1, Tests=1,  \d+ wallclock secs};

    is_deeply \@output, \@expected, '... and the output should be correct';
    like $status, $expected_status,
      '... and the status line should be correct';
    like $summary, $expected_summary,
      '... and the report summary should look correct';

    # run same test twice

    @output = ();
    ok $aggregate = _runtests(
        $harness, [ "$source_tests/harness", 'My Nice Test' ],
        [ "$source_tests/harness", 'My Nice Test Again' ]
      ),
      '... runtests returns the aggregate';

    isa_ok $aggregate, 'TAP::Parser::Aggregator';

    chomp(@output);

    @expected = (
        'My Nice Test ........',
        '1..1',
        'ok 1 - this is a test',
        'ok',
        'My Nice Test Again ..',
        '1..1',
        'ok 1 - this is a test',
        'ok',
        'All tests successful.',
    );
    $status           = pop @output;
    $expected_status  = qr{^Result: PASS$};
    $summary          = pop @output;
    $expected_summary = qr{^Files=2, Tests=2,  \d+ wallclock secs};

    is_deeply \@output, \@expected, '... and the output should be correct';
    like $status, $expected_status,
      '... and the status line should be correct';
    like $summary, $expected_summary,
      '... and the report summary should look correct';

    # normal tests in quiet mode

    @output = ();
    _runtests( $harness_whisper, "$source_tests/harness" );

    chomp(@output);
    @expected = (
        "$source_tests/harness .. ok",
        'All tests successful.',
    );

    $status           = pop @output;
    $expected_status  = qr{^Result: PASS$};
    $summary          = pop @output;
    $expected_summary = qr/^Files=1, Tests=1,  \d+ wallclock secs/;

    is_deeply \@output, \@expected, '... and the output should be correct';
    like $status, $expected_status,
      '... and the status line should be correct';
    like $summary, $expected_summary,
      '... and the report summary should look correct';

    # normal tests in really_quiet mode

    @output = ();
    _runtests( $harness_mute, "$source_tests/harness" );

    chomp(@output);
    @expected = (
        'All tests successful.',
    );

    $status           = pop @output;
    $expected_status  = qr{^Result: PASS$};
    $summary          = pop @output;
    $expected_summary = qr/^Files=1, Tests=1,  \d+ wallclock secs/;

    is_deeply \@output, \@expected, '... and the output should be correct';
    like $status, $expected_status,
      '... and the status line should be correct';
    like $summary, $expected_summary,
      '... and the report summary should look correct';

    # normal tests with failures

    @output = ();
    _runtests( $harness, "$source_tests/harness_failure" );

    $status  = pop @output;
    $summary = pop @output;

    like $status, qr{^Result: FAIL$},
      '... and the status line should be correct';

    my @summary = @output[ 5 .. $#output ];
    @output = @output[ 0 .. 4 ];

    @expected = (
        "$source_tests/harness_failure ..",
        '1..2',
        'ok 1 - this is a test',
        'not ok 2 - this is another test',
        'Failed 1/2 subtests',
    );

    is_deeply \@output, \@expected,
      '... and failing test output should be correct';

    my @expected_summary = (
        'Test Summary Report',
        '-------------------',
        "$source_tests/harness_failure (Wstat: 0 Tests: 2 Failed: 1)",
        'Failed test:',
        '2',
    );

    is_deeply \@summary, \@expected_summary,
      '... and the failure summary should also be correct';

    # quiet tests with failures

    @output = ();
    _runtests( $harness_whisper, "$source_tests/harness_failure" );

    $status   = pop @output;
    $summary  = pop @output;
    @expected = (
        "$source_tests/harness_failure ..",
        'Failed 1/2 subtests',
        'Test Summary Report',
        '-------------------',
        "$source_tests/harness_failure (Wstat: 0 Tests: 2 Failed: 1)",
        'Failed test:',
        '2',
    );

    like $status, qr{^Result: FAIL$},
      '... and the status line should be correct';

    is_deeply \@output, \@expected,
      '... and failing test output should be correct';

    # really quiet tests with failures

    @output = ();
    _runtests( $harness_mute, "$source_tests/harness_failure" );

    $status   = pop @output;
    $summary  = pop @output;
    @expected = (
        'Test Summary Report',
        '-------------------',
        "$source_tests/harness_failure (Wstat: 0 Tests: 2 Failed: 1)",
        'Failed test:',
        '2',
    );

    like $status, qr{^Result: FAIL$},
      '... and the status line should be correct';

    is_deeply \@output, \@expected,
      '... and failing test output should be correct';

    # only show directives

    @output = ();
    _runtests(
        $harness_directives,
        "$source_tests/harness_directives"
    );

    chomp(@output);

    @expected = (
        "$source_tests/harness_directives ..",
        'not ok 2 - we have a something # TODO some output',
        "ok 3 houston, we don't have liftoff # SKIP no funding",
        'ok',
        'All tests successful.',

        # ~TODO {{{ this should be an option
        #'Test Summary Report',
        #'-------------------',
        #"$source_tests/harness_directives (Wstat: 0 Tests: 3 Failed: 0)",
        #'Tests skipped:',
        #'3',
        # }}}
    );

    $status           = pop @output;
    $summary          = pop @output;
    $expected_summary = qr/^Files=1, Tests=3,  \d+ wallclock secs/;

    is_deeply \@output, \@expected, '... and the output should be correct';
    like $summary, $expected_summary,
      '... and the report summary should look correct';

    like $status, qr{^Result: PASS$},
      '... and the status line should be correct';

    # normal tests with bad tap

    @output = ();
    _runtests( $harness, "$source_tests/harness_badtap" );
    chomp(@output);

    @output   = map { trim($_) } @output;
    $status   = pop @output;
    @summary  = @output[ 6 .. ( $#output - 1 ) ];
    @output   = @output[ 0 .. 5 ];
    @expected = (
        "$source_tests/harness_badtap ..",
        '1..2',
        'ok 1 - this is a test',
        'not ok 2 - this is another test',
        '1..2',
        'Failed 1/2 subtests',
    );
    is_deeply \@output, \@expected,
      '... and failing test output should be correct';
    like $status, qr{^Result: FAIL$},
      '... and the status line should be correct';
    @expected_summary = (
        'Test Summary Report',
        '-------------------',
        "$source_tests/harness_badtap (Wstat: 0 Tests: 2 Failed: 1)",
        'Failed test:',
        '2',
        'Parse errors: More than one plan found in TAP output',
    );
    is_deeply \@summary, \@expected_summary,
      '... and the badtap summary should also be correct';

    # coverage testing for _should_show_failures
    # only show failures

    @output = ();
    _runtests( $harness_failures, "$source_tests/harness_failure" );

    chomp(@output);

    @expected = (
        "$source_tests/harness_failure ..",
        'not ok 2 - this is another test',
        'Failed 1/2 subtests',
        'Test Summary Report',
        '-------------------',
        "$source_tests/harness_failure (Wstat: 0 Tests: 2 Failed: 1)",
        'Failed test:',
        '2',
    );

    $status  = pop @output;
    $summary = pop @output;

    like $status, qr{^Result: FAIL$},
      '... and the status line should be correct';
    $expected_summary = qr/^Files=1, Tests=2,  \d+ wallclock secs/;
    is_deeply \@output, \@expected, '... and the output should be correct';

    # check the status output for no tests

    @output = ();
    _runtests( $harness_failures, "$sample_tests/no_output" );

    chomp(@output);

    @expected = (
        "$sample_tests/no_output ..",
        'No subtests run',
        'Test Summary Report',
        '-------------------',
        "$sample_tests/no_output (Wstat: 0 Tests: 0 Failed: 0)",
        'Parse errors: No plan found in TAP output',
    );

    $status  = pop @output;
    $summary = pop @output;

    like $status, qr{^Result: FAIL$},
      '... and the status line should be correct';
    $expected_summary = qr/^Files=1, Tests=2,  \d+ wallclock secs/;
    is_deeply \@output, \@expected, '... and the output should be correct';

    #XXXX
}

sub trim {
    $_[0] =~ s/^\s+|\s+$//g;
    return $_[0];
}

sub _runtests {
    my ( $harness, @tests ) = @_;
    local $ENV{PERL_TEST_HARNESS_DUMP_TAP} = 0;
    my $aggregate = $harness->runtests(@tests);
    return $aggregate;
}

