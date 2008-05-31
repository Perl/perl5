#!/usr/bin/perl -w

use strict;
use lib 't/lib';

use Test::More;
use App::Prove::State;

my @schedule = (

    # last => sub {
    # failed => sub {
    # passed => sub {
    # all => sub {
    # todo => sub {
    # hot => sub {
    # save => sub {
    # adrian => sub {
    {   options        => 'all',
        get_tests_args => [],
        expect         => [
            't/compat/env.t',
            't/compat/failure.t',
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/source.t',
            't/yamlish-writer.t',
        ],
    },
    {   options        => 'failed',
        get_tests_args => [],
        expect         => [
            't/compat/inc_taint.t',
            't/compat/version.t',
        ],
    },
    {   options        => 'passed',
        get_tests_args => [],
        expect         => [
            't/compat/env.t',
            't/compat/failure.t',
            't/source.t',
            't/yamlish-writer.t',
        ],
    },
    {   options        => 'last',
        get_tests_args => [],
        expect         => [
            't/compat/env.t',
            't/compat/failure.t',
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/source.t',
        ],
    },
    {   options        => 'todo',
        get_tests_args => [],
        expect         => [
            't/compat/version.t',
            't/compat/failure.t',
        ],

    },
    {   options        => 'hot',
        get_tests_args => [],
        expect         => [
            't/compat/version.t',
            't/yamlish-writer.t',
            't/compat/env.t',
        ],
    },
    {   options        => 'adrian',
        get_tests_args => [],
        expect         => [
            't/compat/version.t',
            't/yamlish-writer.t',
            't/compat/env.t',
            't/compat/failure.t',
            't/compat/inc_taint.t',
            't/source.t',
        ],
    },
    {   options        => 'failed,passed',
        get_tests_args => [],
        expect         => [
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/compat/env.t',
            't/compat/failure.t',
            't/source.t',
            't/yamlish-writer.t',
        ],
    },
    {   options        => [ 'failed', 'passed' ],
        get_tests_args => [],
        expect         => [
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/compat/env.t',
            't/compat/failure.t',
            't/source.t',
            't/yamlish-writer.t',
        ],
    },
    {   options        => 'slow',
        get_tests_args => [],
        expect         => [
            't/yamlish-writer.t',
            't/compat/env.t',
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/compat/failure.t',
            't/source.t',
        ],
    },
    {   options        => 'fast',
        get_tests_args => [],
        expect         => [
            't/source.t',
            't/compat/failure.t',
            't/compat/version.t',
            't/compat/inc_taint.t',
            't/compat/env.t',
            't/yamlish-writer.t',
        ],
    },
    {   options        => 'old',
        get_tests_args => [],
        expect         => [
            't/compat/env.t',
            't/compat/failure.t',
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/source.t',
            't/yamlish-writer.t',
        ],
    },
    {   options        => 'new',
        get_tests_args => [],
        expect         => [
            't/source.t',
            't/yamlish-writer.t',
            't/compat/inc_taint.t',
            't/compat/version.t',
            't/compat/env.t',
            't/compat/failure.t',
        ],
    },
);

plan tests => @schedule * 2;

for my $test (@schedule) {
    my $state = App::Prove::State->new;
    isa_ok $state, 'App::Prove::State';

    my $desc = $test->{options};

    # Naughty
    $state->{_} = get_state();
    my $options = $test->{options};
    $options = [$options] unless 'ARRAY' eq ref $options;
    $state->apply_switch(@$options);

    my @got = $state->get_tests( @{ $test->{get_tests_args} } );

    unless ( is_deeply \@got, $test->{expect}, "$desc: order OK" ) {
        use Data::Dumper;
        diag( Dumper( { got => \@got, want => $test->{expect} } ) );
    }
}

sub get_state {
    return {
        'generation' => '51',
        'tests'      => {
            't/compat/failure.t' => {
                'last_result'    => '0',
                'last_run_time'  => '1196371471.57738',
                'last_pass_time' => '1196371471.57738',
                'total_passes'   => '48',
                'seq'            => '1549',
                'gen'            => '51',
                'elapsed'        => 0.1230,
                'last_todo'      => '1'
            },
            't/yamlish-writer.t' => {
                'last_result'    => '0',
                'last_run_time'  => '1196371480.5761',
                'last_pass_time' => '1196371480.5761',
                'last_fail_time' => '1196368609',
                'total_passes'   => '41',
                'seq'            => '1578',
                'gen'            => '49',
                'elapsed'        => 12.2983,
                'last_todo'      => '0'
            },
            't/compat/env.t' => {
                'last_result'    => '0',
                'last_run_time'  => '1196371471.42967',
                'last_pass_time' => '1196371471.42967',
                'last_fail_time' => '1196368608',
                'total_passes'   => '48',
                'seq'            => '1548',
                'gen'            => '52',
                'elapsed'        => 3.1290,
                'last_todo'      => '0'
            },
            't/compat/version.t' => {
                'last_result'    => '2',
                'last_run_time'  => '1196371472.96476',
                'last_pass_time' => '1196371472.96476',
                'last_fail_time' => '1196368609',
                'total_passes'   => '47',
                'seq'            => '1555',
                'gen'            => '51',
                'elapsed'        => 0.2363,
                'last_todo'      => '4'
            },
            't/compat/inc_taint.t' => {
                'last_result'    => '3',
                'last_run_time'  => '1196371471.89682',
                'last_pass_time' => '1196371471.89682',
                'total_passes'   => '47',
                'seq'            => '1551',
                'gen'            => '51',
                'elapsed'        => 1.6938,
                'last_todo'      => '0'
            },
            't/source.t' => {
                'last_result'    => '0',
                'last_run_time'  => '1196371479.72508',
                'last_pass_time' => '1196371479.72508',
                'total_passes'   => '41',
                'seq'            => '1570',
                'gen'            => '51',
                'elapsed'        => 0.0143,
                'last_todo'      => '0'
            },
        }
    };
}
