#!/usr/bin/perl -w

use Test::More tests => 129;
my $is_linux = ($^O =~ /linux/);

BEGIN { use_ok('Time::Piece'); }

# Using known epoch 1753440879 = Friday, July 25, 2025 10:54:39 AM GMT
my @known_gmtime    = gmtime(1753440879);  # (39, 54, 10, 25, 6, 125, 5, 206, 0)
my @known_localtime = localtime(1753440879);

# Basic partial date parsing with localtime() defaults
{
    my $tp = Time::Piece->strptime( "15 Mar", "%d %b",
        { defaults => \@known_localtime } );
    is( $tp->mday, 15,   "Day is correctly parsed" );
    is( $tp->mon,  3,    "Month is correctly parsed (March = 3)" );
    is( $tp->year, 2025, "Correct year taken from defaults" );
}

# Basic partial date parsing with time parts
{
    my $tp = Time::Piece->strptime( "15 Mar", "%d %b",
        { defaults => [ localtime(1753440879) ] } );
    is( $tp->mday, 15,   "Day is correctly parsed" );
    is( $tp->mon,  3,    "Month is correctly parsed (March = 3)" );
    is( $tp->year, 2025, "Correct year taken from defaults" );
}

# Partial date parsing with gmtime() defaults
{
    my $tp =
      Time::Piece->strptime( "10:30", "%H:%M", { defaults => \@known_gmtime } );
    is( $tp->hour, 10,   "Hour is correctly parsed" );
    is( $tp->min,  30,   "Minute is correctly parsed" );
    is( $tp->year, 2025, "Correct year taken from gmtime defaults" );
}

# Custom default array
{
    my @custom_defaults =
      ( 45, 30, 14, 25, 11, 119, 3, 358, 0 );    # 2019-12-25 14:30:45
    my $tp = Time::Piece->strptime( "07:15", "%H:%M",
        { defaults => \@custom_defaults } );
    is( $tp->hour, 7,    "Hour is correctly parsed" );
    is( $tp->min,  15,   "Minute is correctly parsed" );
    is( $tp->sec,  45,   "Seconds taken from defaults" );
    is( $tp->year, 2019, "Year taken from defaults" );
}

# Validation - non-array ref should fail
{
    my $tp = eval {
        Time::Piece->strptime( "15 Mar", "%d %b",
            { defaults => "not an array" } );
    };
    ok( $@, "Error when defaults is not an array ref" );
    like(
        $@,
        qr/defaults must be an array reference/,
        "Correct error message for non-array ref"
    );
}

# Validation - array with wrong number of elements
{
    my @short_array = ( 1, 2, 3 );
    my $tp          = eval {
        Time::Piece->strptime( "15 Mar", "%d %b",
            { defaults => \@short_array } );
    };
    ok( $@, "Error when defaults array has wrong number of elements" );
    like(
        $@,
        qr/defaults array must have/,
        "Correct error message for wrong array size"
    );
}

# Parsed values always override defaults
{
    my @defaults_2020 = ( 0, 0, 0, 1, 0, 120, 3, 1, 0 );   # 2020-01-01 00:00:00
    my $tp            = Time::Piece->strptime( "2019/07/15", "%Y/%m/%d",
        { defaults => \@defaults_2020 } );
    is( $tp->year, 2019, "Parsed year overrides default" );
    is( $tp->mon,  7,    "Parsed month overrides default" );
    is( $tp->mday, 15,   "Parsed day overrides default" );
}

# Basic partial date parsing with hashref defaults
{
    my $tp = Time::Piece->strptime(
        "15 Mar", "%d %b",
        {
            defaults => {
                year => 125,    # 2025
                hour => 14,
                min  => 30
            }
        }
    );
    is( $tp->mday, 15,   "Day is correctly parsed" );
    is( $tp->mon,  3,    "Month is correctly parsed (March = 3)" );
    is( $tp->year, 2025, "Year taken from hashref defaults" );
    is( $tp->hour, 14,   "Hour taken from hashref defaults" );
    is( $tp->min,  30,   "Minute taken from hashref defaults" );
    is( $tp->sec, 0,
        "Seconds use hardcoded default (not specified in hashref)" );
}

# Test that only specified fields are overridden
{
    my $tp = Time::Piece->strptime(
        "10:45", "%H:%M",
        {
            defaults => {
                year => 119,    # 2019
                mday => 25,
                mon  => 11      # December
            }
        }
    );
    is( $tp->hour, 10,   "Hour is correctly parsed (overrides hashref)" );
    is( $tp->min,  45,   "Minute is correctly parsed (overrides hashref)" );
    is( $tp->year, 2019, "Year taken from hashref defaults" );
    is( $tp->mday, 25,   "Day taken from hashref defaults" );
    is( $tp->mon,  12,   "Month taken from hashref defaults (December = 12)" );
    is( $tp->sec,  0,    "Seconds use hardcoded default" );
}

# Test with all possible field names
{
    my $tp = Time::Piece->strptime(
        "1970", "%Y",
        {    # Simple parsing to test defaults
            defaults => {
                sec   => 45,
                min   => 30,
                hour  => 14,
                mday  => 25,
                mon   => 11,
                year  => 119,
                wday  => 3,
                yday  => 358,
                isdst => 1
            }
        }
    );
    is( $tp->sec,  45,   "Seconds from hashref defaults" );
    is( $tp->min,  30,   "Minutes from hashref defaults" );
    is( $tp->hour, 14,   "Hours from hashref defaults" );
    is( $tp->mday, 25,   "Day from hashref defaults" );
    is( $tp->mon,  12,   "Month from hashref defaults" );
    is( $tp->year, 1970, "Parsed year overrides hashref default" );
}

# Test that invalid field names are silently ignored
{
    my $tp = Time::Piece->strptime(
        "15 Mar", "%d %b",
        {
            defaults => {
                year          => 125,
                invalid_field => 999,
                bad_name      => "ignored",
                hour          => 15
            }
        }
    );
    is( $tp->mday, 15,   "Day is correctly parsed" );
    is( $tp->mon,  3,    "Month is correctly parsed" );
    is( $tp->year, 2025, "Year taken from valid hashref field" );
    is( $tp->hour, 15,   "Hour taken from valid hashref field" );
}

# Test that parsed values override hashref defaults
{
    my $tp = Time::Piece->strptime(
        "2023/08/10",
        "%Y/%m/%d",
        {
            defaults => {
                year => 125,
                mon  => 5,
                mday => 1,
                hour => 12
            }
        }
    );
    is( $tp->year, 2023, "Parsed year overrides hashref default" );
    is( $tp->mon,  8,    "Parsed month overrides hashref default" );
    is( $tp->mday, 10,   "Parsed day overrides hashref default" );
    is( $tp->hour, 12,   "Unparsed hour taken from hashref default" );
}

# Test Time::Piece object defaults - basic functionality
{
    my $tp_defaults =
      localtime(1753440879);    # Friday, July 25, 2025 (local time)
    my $tp =
      Time::Piece->strptime( "15 Mar", "%d %b", { defaults => $tp_defaults } );

    is( $tp->mday, 15,                 "Day is correctly parsed" );
    is( $tp->mon,  3,                  "Month is correctly parsed" );
    is( $tp->year, 2025,               "Year taken from object defaults" );
    is( $tp->hour, $tp_defaults->hour, "Hour taken from object defaults" );
    is( $tp->min,  $tp_defaults->min,  "Minute taken from object defaults" );
    is( $tp->sec,  $tp_defaults->sec,  "Second taken from object defaults" );
}

# Test Time::Piece object defaults - basic functionality
{
    my $tp = Time::Piece->strptime( "15 Mar", "%d %b",
        { defaults => scalar localtime(1753440879) } );

    is( $tp->mday, 15,   "Day is correctly parsed" );
    is( $tp->mon,  3,    "Month is correctly parsed" );
    is( $tp->year, 2025, "Year taken from object defaults" );
    is( $tp->min,  54,   "Minute taken from object defaults" );
    is( $tp->sec,  39,   "Second taken from object defaults" );
}

# Test Time::Piece object defaults - c_islocal copying (localtime object)
{
    my $tp_local = localtime(1753440879);
    my $tp =
      Time::Piece->strptime( "10:30", "%H:%M", { defaults => $tp_local } );

    is( $tp->[Time::Piece::c_islocal],
        1, "c_islocal=1 copied from localtime defaults object" );
    is( $tp->hour, 10, "Hour correctly parsed" );
    is( $tp->min,  30, "Minute correctly parsed" );
    is( $tp->year, $tp_local->year,
        "Year taken from localtime defaults object" );
}

# Test Time::Piece object defaults - c_islocal copying (gmtime object)
{
    my $tp_gmt = gmtime(1753440879);
    my $tp = Time::Piece->strptime( "14:45", "%H:%M", { defaults => $tp_gmt } );

    is( $tp->[Time::Piece::c_islocal], 0, "c_islocal=0 is default for gmtime" );
    is( $tp->hour, 14,            "Hour correctly parsed" );
    is( $tp->min,  45,            "Minute correctly parsed" );
    is( $tp->year, $tp_gmt->year, "Year taken from gmtime defaults object" );
}

# Test that parsed values override Time::Piece object defaults
{
    my $tp_defaults = localtime(1609459200);    # 2021-01-01 00:00:00
    my $tp          = Time::Piece->strptime(
        "2023/08/15 16:30:45",
        "%Y/%m/%d %H:%M:%S",
        { defaults => $tp_defaults }
    );

    is( $tp->year, 2023, "Parsed year" );
    is( $tp->mon,  8,    "Parsed month" );
    is( $tp->mday, 15,   "Parsed day overrides object default" );
    is( $tp->hour, 16,   "Parsed hour overrides object default" );
    is( $tp->min,  30,   "Parsed minute overrides object default" );
    is( $tp->sec,  45,   "Parsed second overrides object default" );
}

# Test error handling - invalid object
{
    my $not_timepiece = bless {}, 'Some::Other::Class';
    my $tp = eval {
        Time::Piece->strptime( "15 Mar", "%d %b",
            { defaults => $not_timepiece } );
    };
    ok( $@, "Error when defaults is not a Time::Piece object" );
    like( $@, qr/defaults must be an /,
        "Correct error message for bad object" );
}

# Test error handling - plain scalar
{
    my $tp = eval {
        Time::Piece->strptime( "15 Mar", "%d %b",
            { defaults => "not an object" } );
    };
    ok( $@, "Error when defaults is a plain scalar" );
    like( $@, qr/defaults must be an /, "Correct error message for scalar" );
}

# Test shorthand syntax - basic functionality with format
{
    my $tp_defaults =
      localtime(1753440879);    # Friday, July 25, 2025 (local time)
    my $tp = Time::Piece->strptime( "15 Mar", "%d %b", $tp_defaults );

    is( $tp->mday, 15,   "Shorthand: Day is correctly parsed" );
    is( $tp->mon,  3,    "Shorthand: Month is correctly parsed" );
    is( $tp->year, 2025, "Shorthand: Year taken from Time::Piece object" );
    is( $tp->hour, $tp_defaults->hour, "Shorthand: Hour taken from object" );
    is( $tp->min,  $tp_defaults->min,  "Shorthand: Minute taken from object" );
    is( $tp->sec,  $tp_defaults->sec,  "Shorthand: Second taken from object" );
}

# Test shorthand syntax - c_islocal copying
{
    my $tp1 =
      Time::Piece->strptime( "15 Mar", "%d %b", scalar localtime(1753440879) );
    my $tp2 =
      Time::Piece->strptime( "15 Mar", "%d %b", scalar gmtime(1753440879) );

    is( $tp1->[Time::Piece::c_islocal],
        1, "Shorthand: c_islocal=1 copied from localtime object" );
    is( $tp2->[Time::Piece::c_islocal],
        0, "Shorthand: c_islocal=0 copied from gmtime object" );
}

# Test shorthand syntax vs hash syntax equivalence
{
    my $tp_defaults = localtime(1753440879);

    my $tp_shorthand = Time::Piece->strptime( "10:30", "%H:%M", $tp_defaults );
    my $tp_hash =
      Time::Piece->strptime( "10:30", "%H:%M", { defaults => $tp_defaults } );
    my $tp_array = Time::Piece->strptime( "10:30", "%H:%M",
        { defaults => [@$tp_defaults] } );

    is( $tp_shorthand->year, $tp_hash->year,
        "Shorthand and hash have same year" );
    is( $tp_shorthand->mon, $tp_hash->mon,
        "Shorthand and hash syntax give same month" );
    is( $tp_shorthand->mday, $tp_hash->mday,
        "Shorthand and hash syntax give same day" );
    is( $tp_shorthand->hour, $tp_hash->hour,
        "Shorthand and hash syntax give same hour" );
    is( $tp_shorthand->min, $tp_hash->min,
        "Shorthand and hash syntax give same minute" );
    is(
        $tp_shorthand->[Time::Piece::c_islocal],
        $tp_hash->[Time::Piece::c_islocal],
        "Shorthand and hash syntax give same c_islocal"
    );
    is( $tp_shorthand->year, $tp_array->year,
        "Shorthand and array syntax give same year" );
    is( $tp_shorthand->mon, $tp_array->mon,
        "Shorthand and array syntax give same month" );
    is( $tp_shorthand->mday, $tp_array->mday,
        "Shorthand and array syntax give same day" );
    is( $tp_shorthand->hour, $tp_array->hour,
        "Shorthand and array syntax give same hour" );
    is( $tp_shorthand->min, $tp_array->min,
        "Shorthand and array syntax give same minute" );
    isnt(
        $tp_shorthand->[Time::Piece::c_islocal],
        $tp_array->[Time::Piece::c_islocal],
        "Shorthand and array different c_islocal"
    );

}

# Test year shortcuts in hash ref defaults - actual years (>=1000)
{
    my $tp1 = Time::Piece->strptime( "15 Mar", "%d %b",
        { defaults => { year => 2023 } } );
    is( $tp1->year, 2023, "Year shortcut: 2023 converted correctly" );
    is( $tp1->mday, 15,   "Year shortcut: Day parsed correctly" );
    is( $tp1->mon,  3,    "Year shortcut: Month parsed correctly" );

    my $tp2 = Time::Piece->strptime( "01 Jan", "%d %b",
        { defaults => { year => 1970 } } );
    is( $tp2->year, 1970, "Year shortcut: 1970 converted correctly" );

    my $tp3 = Time::Piece->strptime( "01 Jan", "%d %b",
        { defaults => { year => 1000 } } );
    is( $tp3->year, 1000,
        "Year shortcut: 1000 converted correctly (boundary)" );

    my $tp4 = Time::Piece->strptime( "10:30", "%H:%M",
        { defaults => { year => 2025, mon => 6, mday => 15 } } );
    is( $tp4->year, 2025, "Year shortcut: 2025 with other fields" );
    is( $tp4->mon,  7,    "Year shortcut: Month field unaffected" );
    is( $tp4->mday, 15,   "Year shortcut: Day field unaffected" );
}

# Test year shortcuts - offset years
{
    my $tp1 = Time::Piece->strptime( "15 Mar", "%d %b",
        { defaults => { year => 123 } } );
    is( $tp1->year, 2023, "Year offset: 123 stays as offset (2023)" );

    my $tp2 = Time::Piece->strptime( "01 Jan", "%d %b",
        { defaults => { year => 70 } } );
    is( $tp2->year, 1970, "Year offset: 70 stays as offset (1970)" );

    my $tp3 =
      Time::Piece->strptime( "01 Jan", "%d %b", { defaults => { year => 0 } } );
    is( $tp3->year, 1900, "Year offset: 0 stays as offset (1900)" );

    my $tp4 = Time::Piece->strptime( "01 Jan", "%d %b",
        { defaults => { year => 999 } } );
    is( $tp4->year, 2899, "Year offset: 999 stays as offset (2899)" );
}

# Test strptime($string, {defaults => ...}) - format defaults to $DATE_FORMAT
{
    # Default format is: "%a, %d %b %Y %H:%M:%S %Z"
    my $date_string = "Fri, 15 Mar 2025 14:30:45 GMT";

    # Test with array ref defaults, no format specified
    my @arr_defaults = ( 0, 0, 0, 1, 0, 125, 0, 0 );    # 2025-01-01 defaults
    my $tp1 =
      Time::Piece->strptime( $date_string, { defaults => \@arr_defaults } );
    is( $tp1->mday, 15,   "No format, array defaults: Day parsed correctly" );
    is( $tp1->mon,  3,    "No format, array defaults: Month parsed correctly" );
    is( $tp1->year, 2025, "No format, array defaults: Year parsed correctly" );
    is( $tp1->hour, 14,   "No format, array defaults: Hour parsed correctly" );
    is( $tp1->min,  30, "No format, array defaults: Minute parsed correctly" );

    # Test with hash ref defaults, no format specified
    my $tp2 = Time::Piece->strptime( $date_string,
        { defaults => { year => 2023, sec => 50 } } );
    is( $tp2->mday, 15,   "No format, hash defaults: Day parsed correctly" );
    is( $tp2->mon,  3,    "No format, hash defaults: Month parsed correctly" );
    is( $tp2->year, 2025, "No format, hash defaults: Parsed year overrides" );
    is( $tp2->hour, 14,   "No format, hash defaults: Hour parsed correctly" );
    is( $tp2->sec,  45,   "No format, hash defaults: Parsed second overrides" );

    # Test with Time::Piece object defaults, no format specified
    my $tp_obj = Time::Piece->localtime(1609459200);    # 2021-01-01
    my $tp3    = Time::Piece->strptime( $date_string, { defaults => $tp_obj } );
    is( $tp3->mday, 15, "No format, object defaults: Day parsed correctly" );
    is( $tp3->mon,  3,  "No format, object defaults: Month parsed correctly" );
    is( $tp3->year, 2025, "No format, object defaults: Parsed year overrides" );
    is( $tp3->hour, 14,   "No format, object defaults: Hour parsed correctly" );
    is( $tp3->[Time::Piece::c_islocal], 1, "No format, object copied local" );
}

# Test error cases with no format specified
{
    # Test invalid defaults type
    my $tp = eval {
        Time::Piece->strptime( "Fri, 15 Mar 2025 10:30:00 GMT",
            { defaults => "invalid" } );
    };
    ok( $@, "No format, error: Invalid defaults type fails" );
    like(
        $@,
        qr/defaults must be an /,
        "No format, error: Correct error message"
    );
}

# Test shorthand syntax - format defaults to $DATE_FORMAT
SKIP: {
    skip "Default format tests for Linux only.", 4
      unless $is_linux
      && ( $ENV{AUTOMATED_TESTING}
        || $ENV{NONINTERACTIVE_TESTING}
        || $ENV{PERL_BATCH} );

    Time::Piece->use_locale();

    my $tp_defaults = localtime(1753440879);

    # Using default format "%a, %d %b %Y %H:%M:%S %Z"
    my $input_string = $tp_defaults->strftime();

    # Replace specific parts to test parsing
    $input_string =~ s/25/15/;

    my $tp = Time::Piece->strptime( $input_string, $tp_defaults );

    is( $tp->mday, 15,   "Shorthand no format: Day is correctly parsed" );
    is( $tp->mon,  7,    "Shorthand no format: Month is correctly parsed" );
    is( $tp->year, 2025, "Shorthand no format: Year taken from defaults" );
    is( $tp->[Time::Piece::c_islocal],
        1, "Shorthand no format, object copied local" );
}

