#!/usr/bin/perl
use strict;
use warnings;
use Carp;
use Cwd;
use File::Spec;
use File::Temp qw( tempdir );
use Capture::Tiny qw( capture );
use Test::More tests =>  7;
use lib qw( lib );
use ExtUtils::ParseXS::Utilities qw(
    Warn
    blurt
    death
);

my $self = {};
$self->{line} = [];
$self->{line_no} = [];

{
    $self->{line} = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
    ];
    $self->{line_no} = [ 17 .. 20 ];
    $self->{filename} = 'myfile1';

    my $message = 'Warning: Ignoring duplicate alias';
    
    my ($stdout, $stderr) = capture {
        Warn( $self, $message);
    };
    like( $stderr,
        qr/$message in $self->{filename}, line 20/,
        "Got expected Warn output",
    );
}

{
    $self->{line} = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
        'Epsilon',
    ];
    $self->{line_no} = [ 17 .. 20 ];
    $self->{filename} = 'myfile2';

    my $message = 'Warning: Ignoring duplicate alias';
    my ($stdout, $stderr) = capture {
        Warn( $self, $message);
    };
    like( $stderr,
        qr/$message in $self->{filename}, line 19/,
        "Got expected Warn output",
    );
}

{
    $self->{line} = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
    ];
    $self->{line_no} = [ 17 .. 21 ];
    $self->{filename} = 'myfile1';

    my $message = 'Warning: Ignoring duplicate alias';
    my ($stdout, $stderr) = capture {
        Warn( $self, $message);
    };
    like( $stderr,
        qr/$message in $self->{filename}, line 17/,
        "Got expected Warn output",
    );
}

{
    $self->{line} = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
    ];
    $self->{line_no} = [ 17 .. 20 ];
    $self->{filename} = 'myfile1';
    $self->{errors} = 0;


    my $message = 'Error: Cannot parse function definition';
    my ($stdout, $stderr) = capture {
        blurt( $self, $message);
    };
    like( $stderr,
        qr/$message in $self->{filename}, line 20/,
        "Got expected blurt output",
    );
    is( $self->{errors}, 1, "Error count incremented correctly" );
}

SKIP: {
    skip "death() not testable as long as it contains hard-coded 'exit'", 1;

    $self->{line} = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
    ];
    $self->{line_no} = [ 17 .. 20 ];
    $self->{filename} = 'myfile1';

    my $message = "Code is not inside a function";
    eval {
        my ($stdout, $stderr) = capture {
            death( $self, $message);
        };
        like( $stderr,
            qr/$message in $self->{filename}, line 20/,
            "Got expected death output",
        );
    };
}

pass("Passed all tests in $0");
