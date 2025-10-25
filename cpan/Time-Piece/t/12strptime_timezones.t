use Test::More;

plan skip_all => "Timezone parsing not required for installation"
  unless ( $ENV{PERL_BATCH}
    || $ENV{AUTOMATED_TESTING}
    || $ENV{NONINTERACTIVE_TESTING} );

use Time::Piece;

sub test_parse
{
    my ( $str, $fmt, $tests, $desc_prefix, $opts ) = @_;
    $opts ||= {};

    my $tp = eval {
        if ( defined $opts->{islocal} ) {
            Time::Piece->strptime( $str, $fmt,
                { islocal => $opts->{islocal} } );
        } else {
            Time::Piece->strptime( $str, $fmt );
        }
    };

    ok( !$@, "$desc_prefix: Parsed successfully" ) or diag("Error: $@");
    return unless $tp;

    for my $field ( keys %$tests ) {

        if ( $field eq 'hour_range' ) {
            my ( $min, $max ) = @{ $tests->{$field} };
            ok(
                $tp->hour >= $min && $tp->hour <= $max,
                "$desc_prefix: hour in range [$min, $max] (got "
                  . $tp->hour . ")"
            );
        } elsif ( $field eq 'islocal' ) {
            is( $tp->[Time::Piece::c_islocal],
                $tests->{$field}, "$desc_prefix: islocal = $tests->{$field}" );
        } else {
            is( $tp->$field, $tests->{$field},
                "$desc_prefix: $field = $tests->{$field}" );
        }
    }

    return $tp;
}

sub with_tz
{
    my ( $tz, $code ) = @_;
    my $orig_tz = $ENV{TZ};
    local $ENV{TZ} = $tz;
    Time::Piece::_tzset();
    $code->();
    if ( defined $orig_tz ) {
        $ENV{TZ} = $orig_tz;
    } else {
        delete $ENV{TZ};
    }
    Time::Piece::_tzset();
}

# ============================================================================
# %z NUMERIC TIMEZONE OFFSET TESTS
# ============================================================================

# Basic %z offset tests - how time is adjusted to UTC
my @z_offset_tests = (

    # [offset, input_hour, expected_hour, expected_min, desc]
    [ "+0000", 10, 10, 30, "UTC/Zero offset" ],
    [ "+0100", 10, 9,  30, "UTC+1" ],
    [ "+0500", 10, 5,  30, "UTC+5" ],
    [ "+0530", 10, 5,  0,  "UTC+5:30" ],
    [ "-0100", 10, 11, 30, "UTC-1" ],
    [ "-0500", 10, 15, 30, "UTC-5" ],
    [ "-0730", 10, 18, 0,  "UTC-7:30" ],

    # ISO 8601 [+-]HH format (verify existing support)
    [ "+00", 10, 10, 30, "UTC (HH format)" ],
    [ "+05", 10, 5,  30, "UTC+5 (HH format)" ],
    [ "-08", 10, 18, 30, "UTC-8 (HH format)" ],

    # ISO 8601 [+-]HH:MM format (new support)
    [ "+00:00", 10, 10, 30, "UTC (HH:MM format)" ],
    [ "+01:00", 10, 9,  30, "UTC+1 (HH:MM format)" ],
    [ "+05:30", 10, 5,  0,  "UTC+5:30 (HH:MM format)" ],
    [ "-01:00", 10, 11, 30, "UTC-1 (HH:MM format)" ],
    [ "-07:30", 10, 18, 0,  "UTC-7:30 (HH:MM format)" ],
);

for my $test (@z_offset_tests) {
    my ( $offset, $hour_in, $hour_out, $min_out, $desc ) = @$test;
    test_parse(
        "2025-01-15 $hour_in:30:45 $offset",
        "%Y-%m-%d %H:%M:%S %z",
        {
            year => 2025,
            mon  => 1,
            mday => 15,
            hour => $hour_out,
            min  => $min_out,
            sec  => 45
        },
        "%z $desc"
    );
}

# Day wrapping tests with %z
my @z_day_wrap_tests = (

    # [offset, time, expected_day, expected_hour, desc]
    # Positive offsets that wrap to previous day
    [ "+0800", "02:00:00", 14, 18, "wrap to previous day" ],
    [ "+1200", "01:30:00", 14, 13, "wrap to previous day with half hour" ],
    [ "+1400", "00:30:00", 14, 10, "maximum positive offset wrap" ],

    # Negative offsets that wrap to next day
    [ "-0400", "22:00:00", 16, 2,  "wrap to next day" ],
    [ "-0800", "20:45:00", 16, 4,  "wrap to next day with minutes" ],
    [ "-1200", "23:30:00", 16, 11, "maximum negative offset wrap" ],
);

for my $test (@z_day_wrap_tests) {
    my ( $offset, $time, $exp_day, $exp_hour, $desc ) = @$test;
    test_parse(
        "2025-01-15 $time $offset",
        "%Y-%m-%d %H:%M:%S %z",
        { year => 2025, mon => 1, mday => $exp_day, hour => $exp_hour },
        "%z day wrap: $offset $desc"
    );
}

# Month/Year boundary wrapping with %z
my @z_boundary_tests = (

    # [date_time, offset, exp_year, exp_mon, exp_day, exp_hour, desc]
    [ "2025-01-01 01:00:00", "+0300", 2024, 12, 31, 22, "Year boundary back" ],
    [ "2024-12-31 23:30:00", "-0200", 2025, 1, 1, 1, "Year boundary forward" ],
    [ "2025-01-31 23:00:00", "-0200", 2025, 2, 1, 1, "Month boundary forward" ],
    [ "2024-02-29 01:00:00", "+0500", 2024, 2, 28, 20, "Leap day backward" ],
    [ "2024-02-28 23:00:00", "-0300", 2024, 2, 29, 2,  "Leap day forward" ],
);

for my $test (@z_boundary_tests) {
    my ( $datetime, $offset, $exp_year, $exp_mon, $exp_day, $exp_hour, $desc )
      = @$test;
    test_parse(
        "$datetime $offset",
        "%Y-%m-%d %H:%M:%S %z",
        {
            year => $exp_year,
            mon  => $exp_mon,
            mday => $exp_day,
            hour => $exp_hour
        },
        "%z boundary: $desc"
    );
}

# ============================================================================
# %Z TIMEZONE NAME TESTS
# ============================================================================

# Basic %Z timezone name recognition
my @Z_basic_tests = (
    [ "GMT", 10, 0, "GMT recognized as UTC" ],
    [ "UTC", 10, 0, "UTC recognized" ],
    [ "PST", 10, 0, "PST treated as GMT (islocal=0)" ],
    [ "EST", 10, 0, "EST treated as GMT (islocal=0)" ],
);

for my $test (@Z_basic_tests) {
    my ( $tz, $exp_hour, $exp_islocal, $desc ) = @$test;
    test_parse(
        "2025-01-15 10:30:45 $tz",
        "%Y-%m-%d %H:%M:%S %Z",
        { year => 2025, hour => $exp_hour, islocal => $exp_islocal },
        "%Z $desc"
    );
}

# %Z with GMT to local conversion
with_tz(
    "EST5EDT4,M3.2.0/2,M11.1.0/2",
    sub {
        test_parse(
            "2025-01-15 15:30:45 GMT",
            "%Y-%m-%d %H:%M:%S %Z",
            { hour => 15, islocal => 0 },
            "%Z GMT->GMT: default"
        );

        test_parse(
            "2025-01-15 15:30:45 GMT",
            "%Y-%m-%d %H:%M:%S %Z",
            { hour => 10, islocal => 1 },
            "%Z GMT->Local: forced local",
            { islocal => 1 }
        );

        test_parse(
            "2025-01-15 15:30:45 +0300",
            "%Y-%m-%d %H:%M:%S %z",
            { hour => 7, islocal => 1 },
            "%z +0300->Local",
            { islocal => 1 }
        );

        test_parse(
            "2025-01-15 01:00:00 GMT",
            "%Y-%m-%d %H:%M:%S %Z",
            { mday => 14, hour => 20, islocal => 1 },
            "%Z GMT day boundary",
            { islocal => 1 }
        );
    }
);

# ============================================================================
# DST TESTS (Daylight Saving Time)
# ============================================================================

# Mar 10, 2024 - Daylight Saving Time Started
# DST Spring Forward (2:00 AM -> 3:00 AM)
with_tz(
    "EST5EDT4,M3.2.0/2,M11.1.0/2",
    sub {
        # Valid time before transition
        test_parse(
            "2024-03-10 01:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, mon => 3, mday => 10, hour => 1, min => 30 },
            "DST spring: before transition",
            { islocal => 1 }
        );

        # Non-existent time during spring forward
        my $tp = test_parse(
            "2024-03-10 02:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, mon => 3, mday => 10, hour => 2 },
            "DST spring: non-existent time",
            { islocal => 1 }
        );

        # Valid time after transition
        test_parse(
            "2024-03-10 03:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 3, min => 30 },
            "DST spring: after transition",
            { islocal => 1 }
        );

        # GMT during DST should be unaffected
        test_parse(
            "2024-03-10 07:30:00 GMT",
            "%Y-%m-%d %H:%M:%S %Z",
            { year => 2024, hour => 7, islocal => 0 },
            "DST spring: GMT unaffected"
        );

        # GMT to local during DST
        test_parse(
            "2024-03-10 07:30:00 GMT",
            "%Y-%m-%d %H:%M:%S %Z",
            { year => 2024, hour_range => [ 2, 3 ], islocal => 1 },
            "DST spring: GMT->local conversion",
            { islocal => 1 }
        );

        # %z tests during spring forward transition
        # Time with %z offset that results in non-existent local time
        test_parse(
            "2024-03-10 07:30:00 +0000",    # 7:30 UTC = 2:30 EST (non-existent)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour => 7, min => 30, islocal => 0 },
            "DST spring %z: UTC time during transition (GMT object)"
        );

        # Same but forced to local - should handle non-existent 2:30 AM
        test_parse(
            "2024-03-10 07:30:00 +0000",    # 7:30 UTC = 2:30 EST (non-existent)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour_range => [ 2, 3 ], islocal => 1 },
            "DST spring %z: UTC->local during non-existent time",
            { islocal => 1 }
        );

        # %z offset that results in time before DST transition
        test_parse(
            "2024-03-10 06:00:00 +0000",    # 1:00 EST (before transition)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour => 1, islocal => 1 },
            "DST spring %z: UTC->local before transition",
            { islocal => 1 }
        );

        # %z offset that results in time after DST transition
        test_parse(
            "2024-03-10 08:00:00 +0000",    #4:00 EDT (after transition)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour_range => [ 3, 4 ], islocal => 1 },
            "DST spring %z: UTC->local after transition",
            { islocal => 1 }
        );

        # Non-UTC offset during transition
        test_parse(
            "2024-03-10 10:30:00 +0300",    # 7:30 UTC = 2:30/3:30 local
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour_range => [ 2, 3 ], islocal => 1 },
            "DST spring %z: +0300->local during transition",
            { islocal => 1 }
        );
    }
);

# Nov 3, 2024 - Daylight Saving Time Ended
# DST Fall Back (2:00 AM -> 1:00 AM)
with_tz(
    "EST5EDT4,M3.2.0/2,M11.1.0/2",
    sub {
        # Before ambiguous time
        test_parse(
            "2024-11-03 00:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 0, min => 30 },
            "DST fall: before ambiguous",
            { islocal => 1 }
        );

        # Ambiguous time (occurs twice)
        test_parse(
            "2024-11-03 01:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 1, min => 30 },
            "DST fall: ambiguous time",
            { islocal => 1 }
        );

        # After both occurrences
        test_parse(
            "2024-11-03 02:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 2, min => 30 },
            "DST fall: after ambiguous",
            { islocal => 1 }
        );

        # Explicit timezone during fall-back
        test_parse(
            "2024-11-03 01:30:00 EST",
            "%Y-%m-%d %H:%M:%S %Z",
            { year => 2024, hour => 1 },
            "DST fall: explicit EST",
            { islocal => 1 }
        );

        # %z tests during fall back transition
        # Time with %z that results in first occurrence of 1:30 AM EDT
        test_parse(
            "2024-11-03 05:30:00 +0000",    # = 1:30 AM EDT (first occurrence)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour => 5, min => 30, islocal => 0 },
            "DST fall %z: UTC during ambiguous (GMT object)"
        );

        # Same but forced to local - ambiguous 1:30 AM
        test_parse(
            "2024-11-03 05:30:00 +0000",    # 5:30 UTC = 1:30 AM EDT (first)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour_range => [ 0, 1 ], min => 30, islocal => 1 },
            "DST fall %z: UTC->local first 1:30 AM",
            { islocal => 1 }
        );

        # Time with %z that results in second occurrence of 1:30 AM EST
        test_parse(
            "2024-11-03 06:30:00 +0000",    # 6:30 UTC = 1:30 AM EST (second)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour => 1, min => 30, islocal => 1 },
            "DST fall %z: UTC->local second 1:30 AM",
            { islocal => 1 }
        );

        # %z offset after ambiguous period
        test_parse(
            "2024-11-03 07:00:00 +0000",    # 7:00 UTC = 2:00 AM EST
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour => 2, islocal => 1 },
            "DST fall %z: UTC->local after ambiguous",
            { islocal => 1 }
        );

        # Non-UTC offset during ambiguous time
        test_parse(
            "2024-11-03 09:30:00 +0400",    # 5:30 UTC = 1:30 AM EDT (first)
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour_range => [ 0, 1 ], min => 30, islocal => 1 },
            "DST fall %z: +0400->local during ambiguous",
            { islocal => 1 }
        );

        # Negative offset during fall back
        test_parse(
            "2024-11-03 00:30:00 -0500",   # 0:30-05:00 = 5:30 UTC = 1:30 AM EDT
            "%Y-%m-%d %H:%M:%S %z",
            { year => 2024, hour_range => [ 0, 1 ], min => 30, islocal => 1 },
            "DST fall %z: -0500->local during ambiguous",
            { islocal => 1 }
        );
    }
);

# Different timezone DST rules
with_tz(
    "PST8PDT,M3.2.0/2,M11.1.0/2",
    sub {
        # Pacific timezone spring forward
        test_parse(
            "2024-03-10 02:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 2 },
            "DST Pacific: spring forward",
            { islocal => 1 }
        );

        # GMT to Pacific during summer (PDT)
        test_parse(
            "2024-07-15 20:00:00 GMT",
            "%Y-%m-%d %H:%M:%S %Z",
            { year => 2024, hour_range => [ 12, 13 ], islocal => 1 },
            "DST Pacific: GMT->PDT summer",
            { islocal => 1 }
        );
    }
);

# European DST (different dates than US)
with_tz(
    "CET-1CEST,M3.5.0,M10.5.0/3",
    sub {
        # European spring forward (last Sunday in March)
        test_parse(
            "2024-03-31 02:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 2 },
            "DST Europe: spring forward",
            { islocal => 1 }
        );

        # European fall back (last Sunday in October)
        test_parse(
            "2024-10-27 02:30:00",
            "%Y-%m-%d %H:%M:%S",
            { year => 2024, hour => 2 },
            "DST Europe: fall back",
            { islocal => 1 }
        );
    }
);

done_testing(290);
