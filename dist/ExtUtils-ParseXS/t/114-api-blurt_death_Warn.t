#!/usr/bin/perl
#
# Test the Warn, death() etc methods themselves.

use strict;
use warnings;
$| = 1;
use Test::More tests =>  8;
use File::Spec;
use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib');
use ExtUtils::ParseXS;
use ExtUtils::ParseXS::Utilities qw(
    Warn
    blurt
    death
);
use PrimitiveCapture;

my $self = ExtUtils::ParseXS->new;
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
    $self->{in_filename} = 'myfile1';

    my $message = 'Warning: Ignoring duplicate alias';
    
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        Warn( $self, $message);
    });
    like( $stderr,
        qr/$message in $self->{in_filename}, line 20/,
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
    $self->{in_filename} = 'myfile2';

    my $message = 'Warning: Ignoring duplicate alias';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        Warn( $self, $message);
    });
    like( $stderr,
        qr/$message in $self->{in_filename}, line 19/,
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
    $self->{in_filename} = 'myfile1';

    my $message = 'Warning: Ignoring duplicate alias';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        Warn( $self, $message);
    });
    like( $stderr,
        qr/$message in $self->{in_filename}, line 17/,
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
    $self->{in_filename} = 'myfile1';
    $self->{error_count} = 0;


    my $message = 'Error: Cannot parse function definition';
    my $stderr = PrimitiveCapture::capture_stderr(sub {
        blurt( $self, $message);
    });
    like( $stderr,
        qr/$message in $self->{in_filename}, line 20/,
        "Got expected blurt output",
    );
    is( $self->report_error_count, 1, "Error count incremented correctly" );
}

{

    $self->{line} = [
        'Alpha',
        'Beta',
        'Gamma',
        'Delta',
    ];
    $self->{line_no} = [ 17 .. 20 ];
    $self->{in_filename} = 'myfile1';

    my $message = "reports of my death are premature";
    my ($stderr, $err);
    $stderr = PrimitiveCapture::capture_stderr(sub {
        # NB: can't use 'local' here because under 5.8.x, $self is a
        # pseudo hash and trying to localise gives this error:
        #    Can't localize pseudo-hash element
        my $old = $self->{config_die_on_error};
        $self->{config_die_on_error} = 1; # don't exit
        eval { death( $self, $message); };
        $err = $@;
        $self->{config_die_on_error} = $old;
    });
    like( $err,
        qr/$message in $self->{in_filename}, line 20/,
        "Got expected death output",
    );
    is($stderr, undef, "no stderr noise in death",
    );
}

pass("Passed all tests in $0");
