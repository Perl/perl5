use strict;
use warnings;
use Test::More;
use Time::Piece;
use Time::Seconds;
use Time::Local;

# This test file documents edge cases and oddities in Time::Piece date arithmetic.
# Many of these behaviors may seem counterintuitive but are "working as designed."
# The goal is to clearly document what Time::Piece does, not necessarily what
# users might expect it to do.

my $is_linux = ( $^O =~ /linux/ );
my $is_bsd   = ( $^O =~ /bsd/ );
my $is_mac   = ( $^O =~ /darwin/ );

# Skip DST tests unless in automated testing environment
plan skip_all => "Arithmetic edge case tests not required for installation"
  unless ( $ENV{AUTOMATED_TESTING}
    || $ENV{NONINTERACTIVE_TESTING}
    || $ENV{PERL_BATCH} );

# =============================================================================
# Section 1: Simple Arithmetic with Seconds (Epoch-based)
# =============================================================================
note("=== Section 1: Simple Arithmetic (Epoch-based) ===");

{
    # TEST 1.1: Basic epoch arithmetic with gmtime
    # All +/- operations with seconds use epoch arithmetic
    my $t       = gmtime(1000000000);    # 2001-09-09 01:46:40 GMT
    my $t_plus  = $t + 3600;             # Add 1 hour
    my $t_minus = $t - 3600;             # Subtract 1 hour

    is( $t_plus->hour,  2, 'gmtime + 3600 seconds increases hour by 1' );
    is( $t_minus->hour, 0, 'gmtime - 3600 seconds decreases hour by 1' );
}

{
    # TEST 1.2: Subtraction between two Time::Piece objects
    # Returns Time::Seconds object containing epoch difference
    my $t1   = gmtime(1000003600);
    my $t2   = gmtime(1000000000);
    my $diff = $t1 - $t2;

    isa_ok( $diff, 'Time::Seconds', 'Subtracting two Time::Piece objects' );
    is( $diff->seconds, 3600, 'Difference is 3600 seconds (epoch difference)' );
}

{
    # TEST 1.3: gmtime objects are always UTC (islocal=0)
    # No DST complications for gmtime
    my $t      = gmtime(1362909000);
    my $t_plus = $t + 7200;            # Add 2 hours

    is(
        $t_plus->hour,
        ( $t->hour + 2 ) % 24,
        'gmtime arithmetic is simple UTC arithmetic'
    );
    ok( !$t_plus->[10], 'gmtime result maintains islocal=0' );
}

# =============================================================================
# Section 2: DST Boundary Tests (localtime objects)
# =============================================================================
SKIP: {
    skip "DST tests for Linux/BSD/Mac only", 12
      unless ( $is_linux || $is_bsd || $is_mac );

    note("=== Section 2: DST Boundary Tests ===");

    local $ENV{TZ} = "EST5EDT4,M3.2.0/2,M11.1.0/2";
    Time::Piece::_tzset();

    {
# TEST 2.1: Spring Forward DST transition (adding seconds)
# On 2013-03-10, clocks jump from 2:00 AM EST to 3:00 AM EDT
# Adding 1 hour to 1:30 AM should result in 3:30 AM (not 2:30, which doesn't exist)
        my $before = localtime(1362897000);    # 2013-03-10 01:30:00 EST
        is(
            $before->strftime("%Y-%m-%d %H:%M:%S %Z"),
            '2013-03-10 01:30:00 EST',
            'Before spring-forward: 1:30 AM EST'
        );

        my $after = $before + 3600;            # Add 1 hour (3600 seconds)
        is(
            $after->strftime("%Y-%m-%d %H:%M:%S %Z"),
            '2013-03-10 03:30:00 EDT',
            'After adding 3600s: 3:30 AM EDT (skipped over 2:30 AM)'
        );
        is( $after->hour, 3, "hour is 3" );
    }

    {
        # TEST 2.2: Fall Back DST transition (adding seconds)
        # On 2013-11-03, clocks fall back from 2:00 AM EDT to 1:00 AM EST
        # The hour from 1:00-2:00 occurs twice
        my $before =
          localtime(1383454800);    # 2013-11-03 01:00:00 EDT (first occurrence)
        is(
            $before->strftime("%Y-%m-%d %H:%M:%S"),
            '2013-11-03 01:00:00',
            'Before fall-back: 1:00 AM EDT'
        );

        my $after = $before + 3600;    # Add 1 hour
            # This crosses into the second occurrence of 1:00 AM (now EST)
        is(
            $after->strftime("%Y-%m-%d %H:%M:%S"),
            '2013-11-03 01:00:00',
            'After adding 3600s: 1:00 AM EST (second occurrence of 1:00 AM)'
        );
        is( $after->strftime("%Z"), 'EST', 'Timezone is now EST' );
        is( $after->hour,           1,     "hour is 1" );
    }

    {
# TEST 2.3: ODDITY - Subtraction across DST gives epoch difference, not wall-clock difference
# This demonstrates that subtraction uses epoch, not wall-clock time
        my $before_spring = localtime(1362897000);    # 2013-03-10 01:30:00 EST
        my $after_spring  = localtime(1362900600);    # 2013-03-10 03:30:00 EDT

        my $diff = $after_spring - $before_spring;

# Wall-clock shows "2 hours" (1:30 AM to 3:30 AM)
# But epoch difference is only 3600 seconds (1 hour) because 2:00-3:00 didn't exist
        is( $diff->seconds, 3600,
'ODDITY: Across spring DST, wall-clock shows 2h but epoch diff is 1h (3600s)'
        );
        is( $diff->hours, 1,
            'Time::Seconds reports 1 hour, not 2 (epoch-based)' );
    }

    {
        # TEST 2.4: Fall-back subtraction oddity
        # The reverse oddity: wall-clock shows 1 hour, epoch shows more
        my $before_fall = localtime(1383454800);    # 2013-11-03 01:00:00 EDT
        my $after_fall  = localtime(1383462000);    # 2013-11-03 02:00:00 EST

        my $diff = $after_fall - $before_fall;

        # Wall-clock shows "1 hour" (1:00 AM to 2:00 AM)
        # But epoch difference is 7200 seconds because 1:00-2:00 occurred twice
        is( $diff->seconds, 7200,
'ODDITY: Across fall DST, wall-clock shows 1h but epoch diff is 2h (7200s)'
        );
    }

    {
        # TEST 2.5: localtime + seconds maintains islocal=1
        my $t      = localtime(1362909000);
        my $t_plus = $t + 3600;

        ok( $t_plus->[10], 'localtime + seconds maintains islocal=1' );
    }
}

# =============================================================================
# Section 3: add_months() Edge Cases
# =============================================================================
note("=== Section 3: add_months() Edge Cases ===");

{
    # TEST 3.1: ODDITY - Month-end overflow (31-day → 28-day month)
    # Jan 31 + 1 month does NOT clamp to Feb 28
    # Instead: Feb 31 is "3 days past Feb 28" → normalizes to March 3
    my $jan31 =
      gmtime( timegm( 0, 0, 12, 31, 0, 113 ) );    # 2013-01-31 12:00:00 UTC
    my $result = $jan31->add_months(1);

    is( $result->ymd, '2013-03-03',
        'ODDITY: Jan 31 + 1 month = March 3 (not Feb 28) - overflow normalizes'
    );
    is( $result->hour, 12, 'Time of day preserved' );
    ok( !$result->[10], 'gmtime maintains islocal=0 after add_months' );
}

{
    # TEST 3.2: Month-end overflow in leap year
    # Jan 31 + 1 month in leap year
    # Feb 31 is "2 days past Feb 29" → March 2
    my $jan31 =
      gmtime( timegm( 0, 0, 12, 31, 0, 112 ) );    # 2012-01-31 12:00:00 UTC
    my $result = $jan31->add_months(1);

    is( $result->ymd, '2012-03-02',
        'Leap year: Jan 31 + 1 month = March 2 (2 days past Feb 29)' );
}

{
    # TEST 3.3: Month-end overflow (31-day → 30-day month)
    # Aug 31 + 1 month → Sep 31 → Oct 1
    my $aug31 =
      gmtime( timegm( 0, 0, 12, 31, 7, 113 ) );    # 2013-08-31 12:00:00 UTC
    my $result = $aug31->add_months(1);

    is( $result->ymd, '2013-10-01',
        'Aug 31 + 1 month = Oct 1 (1 day past Sep 30)' );
}

{
    # TEST 3.4: Multiple months showing direct calculation
    # Jan 31 + 2 months → March 31 (no February normalization in between)
    my $jan31 =
      gmtime( timegm( 0, 0, 12, 31, 0, 113 ) );    # 2013-01-31 12:00:00 UTC
    my $result = $jan31->add_months(2);

    is( $result->ymd, '2013-03-31',
        'Jan 31 + 2 months = March 31 (direct calculation, no intermediate Feb)'
    );
}

{
    # TEST 3.5: Negative month addition with overflow
    # March 31 - 1 month → Feb 31 → March 3
    my $mar31 =
      gmtime( timegm( 0, 0, 12, 31, 2, 113 ) );    # 2013-03-31 12:00:00 UTC
    my $result = $mar31->add_months(-1);

    is( $result->ymd, '2013-03-03',
        'March 31 - 1 month = March 3 (negative months also normalize)' );
}

{
    # TEST 3.6: Year boundary crossing forward
    # Dec 15 + 2 months → Feb 15 (next year)
    my $dec15 =
      gmtime( timegm( 0, 0, 12, 15, 11, 113 ) );    # 2013-12-15 12:00:00 UTC
    my $result = $dec15->add_months(2);

    is( $result->ymd, '2014-02-15',
        'Dec 15 + 2 months crosses year boundary to Feb 15 next year' );
    is( $result->year, 2014, 'Year correctly increments' );
}

{
    # TEST 3.7: Year boundary crossing backward
    # Jan 15 - 3 months → Oct 15 (previous year)
    my $jan15 =
      gmtime( timegm( 0, 0, 12, 15, 0, 113 ) );    # 2013-01-15 12:00:00 UTC
    my $result = $jan15->add_months(-3);

    is( $result->ymd, '2012-10-15',
        'Jan 15 - 3 months crosses year boundary to Oct 15 previous year' );
    is( $result->year, 2012, 'Year correctly decrements' );
}

SKIP: {
    skip "DST tests for Linux/BSD/Mac only", 6
      unless ( $is_linux || $is_bsd || $is_mac );

    note("=== Section 3b: add_months() DST Behavior ===");

    local $ENV{TZ} = "EST5EDT4,M3.2.0/2,M11.1.0/2";
    Time::Piece::_tzset();

    {
       # TEST 3.8: ODDITY - add_months preserves wall-clock time, not UTC offset
       # Jan 10 07:00 EST (UTC-5) + 3 months → Apr 10 07:00 EDT (UTC-4)
       # The wall-clock hour stays 07:00, but UTC relationship changes
        my $jan = localtime( timegm( 0, 0, 12, 10, 0, 113 ) )
          ;    # 2013-01-10 12:00:00 UTC = 07:00 EST
        is( $jan->strftime("%H:%M %Z"), '07:00 EST', 'Start: 07:00 EST' );

        my $apr = $jan->add_months(3);
        is(
            $apr->strftime("%Y-%m-%d %H:%M"),
            '2013-04-10 07:00',
            'ODDITY: add_months preserves wall-clock time (07:00)'
        );
        is( $apr->strftime("%Z"),
            'EDT',
            'But timezone changed to EDT (UTC offset changed from -5 to -4)' );
    }

    {
        # TEST 3.9: Fall-back DST transition
        # Jul 10 14:00 EDT (UTC-4) + 5 months → Dec 10 14:00 EST (UTC-5)
        my $jul = localtime( timegm( 0, 0, 18, 10, 6, 113 ) )
          ;    # 2013-07-10 18:00 UTC = 14:00 EDT
        is( $jul->strftime("%H:%M %Z"), '14:00 EDT', 'Start: 14:00 EDT' );

        my $dec = $jul->add_months(5);
        is(
            $dec->strftime("%Y-%m-%d %H:%M"),
            '2013-12-10 14:00',
            'Wall-clock time preserved (14:00)'
        );
        is( $dec->strftime("%Z"),
            'EST',
            'Timezone changed to EST (UTC offset changed from -4 to -5)' );
    }
}

# =============================================================================
# Section 4: add_years() Edge Cases
# =============================================================================
note("=== Section 4: add_years() Edge Cases ===");

{
    # TEST 4.1: ODDITY - Leap year → non-leap year
    # Feb 29, 2012 + 1 year → Feb 29, 2013 → March 1, 2013 (normalizes)
    my $feb29 =
      gmtime( timegm( 0, 0, 12, 29, 1, 112 ) );    # 2012-02-29 12:00:00 UTC
    my $result = $feb29->add_years(1);

    is( $result->ymd, '2013-03-01',
'ODDITY: Feb 29 leap year + 1 year = March 1 (Feb 29 normalized in non-leap year)'
    );
}

{
    # TEST 4.2: Leap year → leap year
    # Feb 29, 2012 + 4 years → Feb 29, 2016 (stays on leap day)
    my $feb29 =
      gmtime( timegm( 0, 0, 12, 29, 1, 112 ) );    # 2012-02-29 12:00:00 UTC
    my $result = $feb29->add_years(4);

    is( $result->ymd, '2016-02-29',
        'Feb 29 + 4 years = Feb 29 (leap year to leap year)' );
}

{
    # TEST 4.3: Century leap year edge (2000 → 2100)
    # 2100 is NOT a leap year (not divisible by 400)
    # Feb 29, 2000 + 100 years → Feb 29, 2100 → March 1, 2100
    my $feb29_2000 =
      gmtime( timegm( 0, 0, 12, 29, 1, 100 ) );    # 2000-02-29 12:00:00 UTC
    my $result = $feb29_2000->add_years(100);

    is( $result->ymd, '2100-03-01',
        'Feb 29, 2000 + 100 years = March 1, 2100 (2100 not leap year)' );
}

{
    # TEST 4.4: Negative years
    # 2015-02-28 - 1 year → 2014-02-28
    my $feb28 =
      gmtime( timegm( 0, 0, 12, 28, 1, 115 ) );    # 2015-02-28 12:00:00 UTC
    my $result = $feb28->add_years(-1);

    is( $result->ymd, '2014-02-28', 'Feb 28 - 1 year = Feb 28 previous year' );
}

{
    # TEST 4.5: gmtime maintains islocal=0
    my $t = gmtime( timegm( 0, 0, 12, 15, 5, 113 ) );  # 2013-06-15 12:00:00 UTC
    my $result = $t->add_years(2);

    is( $result->ymd, '2015-06-15', 'add_years works for gmtime' );
    ok( !$result->[10], 'gmtime maintains islocal=0 after add_years' );
}

SKIP: {
    skip "DST tests for Linux/BSD/Mac only", 3
      unless ( $is_linux || $is_bsd || $is_mac );

    note("=== Section 4b: add_years() DST Behavior ===");

    local $ENV{TZ} = "EST5EDT4,M3.2.0/2,M11.1.0/2";
    Time::Piece::_tzset();

    {
# TEST 4.6: add_years preserves wall-clock time across different DST transition dates
# In 2013, spring-forward is March 10; in 2014, it's March 9
# But wall-clock time is still preserved
        my $march =
          localtime( timegm( 0, 30, 6, 10, 2, 113 ) ); # 2013-03-10 01:30:00 EST
        is(
            $march->strftime("%Y-%m-%d %H:%M %Z"),
            '2013-03-10 01:30 EST',
            'Start: 2013-03-10 01:30 EST (day of spring-forward)'
        );

        my $next_year = $march->add_years(1);
        is(
            $next_year->strftime("%Y-%m-%d %H:%M"),
            '2014-03-10 01:30',
            'add_years preserves wall-clock time (01:30)'
        );

        # In 2014, March 10 is AFTER spring-forward (which was March 9)
        is( $next_year->strftime("%Z"),
            'EDT',
            '2014-03-10 is in EDT (spring-forward was March 9 in 2014)' );
    }
}

# =============================================================================
# Section 5: Documented Oddities and Mixed Operations
# =============================================================================
note("=== Section 5: Documented Oddities ===");

{
    # TEST 5.1: ODDITY - Date normalization does not clamp
    # This is the fundamental oddity: invalid dates normalize forward
    my $jan31 = gmtime( timegm( 0, 0, 12, 31, 0, 113 ) );    # 2013-01-31

    # Feb has 28 days, so Feb 31 is 3 days past the end
    my $feb = $jan31->add_months(1);
    is( $feb->mday, 3,
        'ODDITY: Overflow days are added to next month (not clamped)' );
    is( $feb->mon, 3, 'Result is in March (month 3), not February' );
}

{
    # TEST 5.2: Mixed operations - order matters
    # (add_months then add seconds) vs (add seconds then add_months)
    my $base = gmtime( timegm( 0, 0, 12, 31, 0, 113 ) );   # 2013-01-31 12:00:00

    # Path 1: add_months(1) then + 86400 (1 day)
    my $path1 =
      $base->add_months(1) + 86400;    # Jan 31→Mar 3, then +1 day = Mar 4

    # Path 2: + 86400 (1 day) then add_months(1)
    my $path2 =
      ( $base + 86400 )->add_months(1);    # Jan 31→Feb 1, then +1 month = Mar 1

    isnt( $path1->ymd, $path2->ymd,
        'ODDITY: Order of operations matters (add_months vs add seconds)' );
    is( $path1->ymd, '2013-03-04',
        'add_months first: Jan 31→Mar 3, then +1 day = Mar 4' );
    is( $path2->ymd, '2013-03-01',
        'add seconds first: Jan 31→Feb 1, then +1 month = Mar 1' );
}

{
    # TEST 5.3: Subtraction is always epoch-based
    # Even for large time differences, result is always epoch seconds
    my $t1 = gmtime( timegm( 0, 0, 0, 1, 0, 114 ) );    # 2014-01-01 00:00:00
    my $t2 = gmtime( timegm( 0, 0, 0, 1, 0, 113 ) );    # 2013-01-01 00:00:00

    my $diff = $t1 - $t2;

    isa_ok( $diff, 'Time::Seconds',
        'Subtraction always returns Time::Seconds' );
    is( $diff->days, 365, 'One year apart = 365 days (2013 not leap year)' );

    # Can also express as months/years, but these are approximations
    ok( $diff->months > 11 && $diff->months < 13,
        'Time::Seconds can approximate months (but epoch-based)' );
}

{
    # TEST 5.4: Time::Piece + Time::Piece behavior
    # POD claims this "will cause a runtime error" but it actually doesn't
    # Instead, the right-hand Time::Piece is converted to its epoch value
    my $t1 = gmtime(1000000000);    # 2001-09-09 01:46:40
    my $t2 = gmtime(3600);          # 1970-01-01 01:00:00 (3600 epoch seconds)

    my $result;
    eval { $result = $t1 + $t2; };

    ok( !$@,
        'Time::Piece + Time::Piece does NOT throw error (contrary to POD claim)'
    );
    isa_ok( $result, 'Time::Piece', 'Result is a Time::Piece object' );
    is( $result->epoch, 1000003600,
        'Time::Piece + Time::Piece: RHS converted to epoch seconds and added' );

    # This is equivalent to $t1 + $t2->epoch
    my $expected = $t1 + $t2->epoch;
    is( $result->epoch, $expected->epoch,
        'Time::Piece + Time::Piece equivalent to Time::Piece + epoch' );
}

done_testing();
