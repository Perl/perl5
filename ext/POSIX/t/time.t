#!perl -w

BEGIN {
    unshift @INC, "../../t";
    require 'loc_tools.pl';
}

use strict;

use Config;
use POSIX;
use Test::More tests => 49;

# For the first go to UTC to avoid DST issues around the world when testing.  SUS3 says that
# null should get you UTC, but some environments want the explicit names.
# Those with a working tzset() should be able to use the TZ below.
$ENV{TZ} = "EST5EDT";

# It looks like POSIX.xs claims that only VMS and Mac OS traditional
# don't have tzset().  MingW doesn't work.  Cygwin works in some places, but
# not others.  The other Win32's below are guesses.
my $has_tzset = $^O ne "VMS" && $^O ne "cygwin"
             && ($^O ne "MSWin32" || (   $^O eq "MSWin32"
                                      && $Config{make} eq 'nmake'))
             && $^O ne "interix";

SKIP: {
    skip "No tzset()", 1 unless $has_tzset;
    tzset();
    SKIP: {
        my @tzname = tzname();

        # See extensive discussion in GH #22062.
        skip 1 if $tzname[1] ne "EDT";
        is(strftime("%Y-%m-%d %H:%M:%S", 0, 30, 2, 10, 2, 124, 0, 0, 0),
                    "2024-03-10 02:30:00",
                    "strftime() doesnt pay attention to dst");
    }
}

# go to UTC to avoid DST issues around the world when testing.  SUS3 says that
# null should get you UTC, but some environments want the explicit names.
# Those with a working tzset() should be able to use the TZ below.
$ENV{TZ} = "UTC0UTC";

SKIP: {
    skip "No tzset()", 2 unless $has_tzset;
    tzset();
    my @tzname = tzname();
    like($tzname[0], qr/(GMT|UTC)/i, "tzset() to GMT/UTC");
    SKIP: {
        skip "Mac OS X/Darwin doesn't handle this", 1 if $^O =~ /darwin/i;
        like($tzname[1], qr/(GMT|UTC)/i, "The whole year?");
    }
}

if ($^O eq "hpux" && $Config{osvers} >= 11.3) {
    # HP does not support UTC0UTC and/or GMT0GMT, as they state that this is
    # legal syntax but as it has no DST rule, it cannot be used. That is the
    # conclusion of bug
    # QXCR1000896916: Some timezone valuesfailing on 11.31 that work on 11.23
    $ENV{TZ} = "UTC";
}

# asctime and ctime...Let's stay below INT_MAX for 32-bits and
# positive for some picky systems.

is(asctime(CORE::localtime(0)), ctime(0), "asctime() and ctime() at zero");
is(asctime(POSIX::localtime(0)), ctime(0), "asctime() and ctime() at zero");
is(asctime(CORE::localtime(12345678)), ctime(12345678),
   "asctime() and ctime() at 12345678");
is(asctime(POSIX::localtime(12345678)), ctime(12345678),
   "asctime() and ctime() at 12345678");

my $illegal_format = "%!";

# An illegal format could result in an empty result, but many platforms just
# pass it through, or strip off the '%'
sub munge_illegal_format_result($) {
    my $result = shift;
    $result = "" if $result eq $illegal_format || $result eq '!';
    return $result;
}

my $jan_16 = 15 * 86400;

is(munge_illegal_format_result(strftime($illegal_format,
                                        CORE::localtime($jan_16))),
   "", "strftime returns appropriate result for an illegal format");

# Careful!  strftime() is locale sensitive.  Let's take care of that
my $orig_time_loc = 'C';

my $LC_TIME_enabled = locales_enabled('LC_TIME');
if ($LC_TIME_enabled) {
    $orig_time_loc = setlocale(LC_TIME) || die "Cannot get time locale information:  $!";
    setlocale(LC_TIME, "C") || die "Cannot setlocale() to C:  $!";
}

my $ctime_format = "%a %b %d %H:%M:%S %Y\n";
is(ctime($jan_16), strftime($ctime_format, CORE::localtime($jan_16)),
        "get ctime() equal to strftime()");
is(ctime($jan_16), strftime($ctime_format, POSIX::localtime($jan_16)),
        "get localtime() equal to strftime()");

my $ss = chr 223;
unlike($ss, qr/\w/, 'Not internally UTF-8 encoded');
is(ord strftime($ss, CORE::localtime), 223,
   'Format string has correct character');
is(ord strftime($ss, POSIX::localtime(time)),
   223, 'Format string has correct character');
unlike($ss, qr/\w/, 'Still not internally UTF-8 encoded');

my $zh_format = "%Y\x{5e74}%m\x{6708}%d\x{65e5}";
my $zh_expected_result = "1970\x{5e74}01\x{6708}16\x{65e5}";
isnt(strftime($zh_format, CORE::gmtime($jan_16)),
              $zh_expected_result,
           "strftime() UTF-8 format doesn't return UTF-8 in non-UTF-8 locale");

my $utf8_locale = find_utf8_ctype_locale();
SKIP: {
    my $has_time_utf8_locale = ($LC_TIME_enabled && defined $utf8_locale);
    if ($has_time_utf8_locale) {
        my $time_utf8_locale = setlocale(LC_TIME, $utf8_locale);

        # Some platforms don't allow LC_TIME to be changed to a UTF-8 locale,
        # even if we have found one whose LC_CTYPE can be.  The next two tests
        # are invalid on such platforms.  Check for that.  (Examples include
        # OpenBSD, and Alpine Linux without the add-on locales package
        # installed.)
        if (   ! defined $time_utf8_locale
            || ! is_locale_utf8($time_utf8_locale))
        {
            $has_time_utf8_locale = 0;
        }
    }

    skip "No LC_TIME UTF-8 locale", 2 unless $has_time_utf8_locale;

    # By setting LC_TIME only, we verify that the code properly handles the
    # case where that and LC_CTYPE differ
    is(strftime($zh_format, CORE::gmtime($jan_16)),
                $zh_expected_result,
                "strftime() can handle a UTF-8 format;  LC_CTYPE != LCTIME");
    is(strftime($zh_format, POSIX::gmtime($jan_16)),
                $zh_expected_result,
                "Same, but uses POSIX::gmtime; previous test used CORE::");
    setlocale(LC_TIME, "C") || die "Cannot setlocale() to C: $!";
}

my $non_C_locale = $utf8_locale;
if (! defined $non_C_locale) {
    my @locales = find_locales(LC_CTYPE);
    while (@locales) {
        if ($locales[0] ne "C") {
            $non_C_locale = $locales[0];
            last;
        }

        shift @locales;
    }
}

SKIP: {
    skip "No non-C locale", 4 if ! locales_enabled(LC_CTYPE)
                              || ! defined $non_C_locale;
    my $orig_ctype_locale = setlocale(LC_CTYPE)
                            || die "Cannot get ctype locale information:  $!";
    setlocale(LC_CTYPE, $non_C_locale)
                    || die "Cannot setlocale(LC_CTYPE) to $non_C_locale:  $!";

    is(ctime($jan_16), strftime($ctime_format, CORE::localtime($jan_16)),
       "Repeat of ctime() equal to strftime()");
    is(setlocale(LC_CTYPE), $non_C_locale, "strftime restores LC_CTYPE");

    is(munge_illegal_format_result(strftime($illegal_format,
                                            CORE::localtime($jan_16))),
       "", "strftime returns appropriate result for an illegal format");
    is(setlocale(LC_CTYPE), $non_C_locale,
       "strftime restores LC_CTYPE even on failure");

    setlocale(LC_CTYPE, $orig_ctype_locale)
                          || die "Cannot setlocale(LC_CTYPE) back to orig: $!";
}

if ($LC_TIME_enabled) {
    setlocale(LC_TIME, $orig_time_loc)
                            || die "Cannot setlocale(LC_TIME) back to orig: $!";
}

# clock() seems to have different definitions of what it does between POSIX
# and BSD.  Cygwin, Win32, and Linux lean the BSD way.  So, the tests just
# check the basics.
like(clock(), qr/\d*/, "clock() returns a numeric value");
cmp_ok(clock(), '>=', 0, "...and it returns something >= 0");

SKIP: {
    skip "No difftime()", 1 if $Config{d_difftime} ne 'define';
    is(difftime(2, 1), 1, "difftime()");
}

SKIP: {
    skip "No mktime()", 2 if $Config{d_mktime} ne 'define';
    my $time = time();
    is(mktime(CORE::localtime($time)), $time, "mktime()");
    is(mktime(POSIX::localtime($time)), $time, "mktime()");
}

SKIP: {
    skip "'%s' not implemented in strftime", 1 if $^O eq "VMS"
                                               || $^O eq "MSWin32"
                                               || $^O eq "os390";
    # Somewhat arbitrarily, put in 60 seconds of slack;  if this fails, it
    # will likely be off by 1 hour
    ok(abs(POSIX::strftime('%s', localtime) - time) < 60,
       'GH #22351; pr: GH #22369');
}

{
    # GH #22498
    is(strftime(42, CORE::localtime), '42', "strftime() works if format is a number");
    my $obj = bless {}, 'Some::Random::Class';
    is(strftime($obj, CORE::localtime), "$obj", "strftime() works if format is an object");
    my $warnings = '';
    local $SIG{__WARN__} = sub { $warnings .= $_[0] };
    is(strftime(undef, CORE::localtime), '', "strftime() works if format is undef");
    like($warnings, qr/^Use of uninitialized value in subroutine entry /, "strftime(undef, ...) produces expected warning");
}

# Now check the transitioning between standard and daylight savings times.  To
# do this requires setting a timezone.  Unfortunately, timezone specification
# syntax differs incompatibly between systems.  The older PST8PDT style
# prevails on Windows, but is being supplanted by "Europe/Paris" style
# elsewhere.  Debian in particular requires a special package to be installed
# to correctly work with the old style.  Worse, without the package, it still
# can recognize the syntax and correctly get right times that aren't at the
# edge of the transitions.  khw tried the 2004 and 2025 spring forward times,
# and Debian sans-package was exactly 6 hours off the correct values.
# (The older style was U.S. centric, assuming everyone in the world with the
# same longitude obeyed the same rules; the new style can tailor the rules to
# the specific region affected.)

# Tue 01 Jul 2025 05:01:01 PM GMT.  This is chosen as being in the middle of
# Daylight Savings Time.  Below, we set locales, and verify that these
# actually worked by checking that the hour returned is the expected value.
my $reference_time = 1751389261;

my $new_names_all_passed = 0;
my $some_new_name_passed = 0;

SKIP: {   # GH #23878; test that dst fall back works properly
    my $skip_count = 9;
    skip "No mktime()", $skip_count if $Config{d_mktime} ne 'define';

    # Doing this ensures that Windows is expecting a different timezone than
    # the one in the test.  Hence, if the new-style name isn't recognized, the
    # tests will be skipped.  Otherwise, if the test happens to being run on a
    # platform located in the Paris timezone, the check will happen to
    # succeed even though the timezone change failed.
    $ENV{TZ} = "PST8PDT";
    tzset() if $has_tzset;

    my $locale = "Europe/Paris";
    $ENV{TZ} = $locale;
    tzset() if $has_tzset;

    skip "'$locale' not understood", $skip_count
                   if POSIX::strftime("%H", localtime($reference_time)) != 19;

    my $t = 1761436800;     # an hour before time should have changed
    my @fall = (
                 [   -1, "2025-10-26 01:59:59+0200", "Chg -1 hr, 1 sec" ],
                 [    0, "2025-10-26 02:00:00+0200", "Chg -1 hr, 0 sec" ],
                 [    1, "2025-10-26 02:00:01+0200", "Chg -59 min, 59 sec" ],
                 [ 3599, "2025-10-26 02:59:59+0200", "Chg -1 sec" ],
                 [ 3600, "2025-10-26 02:00:00+0100", "At Paris DST fallback" ],
                 [ 3601, "2025-10-26 02:00:01+0100", "Chg +1 sec" ],
                 [ 7199, "2025-10-26 02:59:59+0100", "Chg +1 hr, 59m, 59s" ],
                 [ 7200, "2025-10-26 03:00:00+0100", "Chg +1 hr" ],
                 [ 7201, "2025-10-26 03:00:01+0100", "Chg +1 hr, 1 sec" ],
               );
    my $had_failure = 0;
    for (my $i = 0; $i < @fall; $i++) {
        if (is(POSIX::strftime("%F %T%z", localtime $t + $fall[$i][0]),
               $fall[$i][1], $fall[$i][2]))
        {
            $some_new_name_passed = 1;
        }
        else {
            $had_failure = 1
        }
    }

    $new_names_all_passed = ! $had_failure;
}

SKIP: {   # GH #23878: test that dst spring forward works properly.
    my $skip_count = 9;
    skip "No mktime()", $skip_count if $Config{d_mktime} ne 'define';

    my $locale;

    # For this group of tests, we use the old-style timezone names on systems
    # that don't understand the new ones, and use the new ones on systems that
    # do; this finesses the problem of some systems needing special packages
    # to handle old names properly.

    # The group of tests just before this one set this variable.  If 'false'
    # it means no new name worked, likely because they aren't understood, but
    # also could be because of bugs.
    if ($some_new_name_passed) {
        skip "DST fall back didn't work; spring forward not tested",
                                     $skip_count unless $new_names_all_passed;
        $locale = "America/Los_Angeles";
    }
    else {

        # Use a locale that MS narcissism should be able to handle
        $locale = "PST8PDT";
    }

    $ENV{TZ} = $locale;
    tzset() if $has_tzset;

    # $reference_time is in the middle of summer, dst should be in effect.
    skip "'$locale' not understood", $skip_count if
                POSIX::strftime("%H", localtime($reference_time)) != 10;

    my $t = 1741510800;     # an hour before time should have changed

    my @spring = (
                  [   -1, "2025-03-09 00:59:59-0800", "Chg -1 hr,-1 sec" ],
                  [    0, "2025-03-09 01:00:00-0800", "Chg -1 hr, 0 sec" ],
                  [    1, "2025-03-09 01:00:01-0800", "Chg -59 min,-59 sec" ],
                  [ 3599, "2025-03-09 01:59:59-0800", "Chg -1 sec" ],
                  [ 3600, "2025-03-09 03:00:00-0700",
                                            "At Redmond DST spring forward" ],
                  [  3601, "2025-03-09 03:00:01-0700", "Chg +1 sec" ],
                  [  7199, "2025-03-09 03:59:59-0700", "Chg +1 hr, 59m,59s" ],
                  [  7200, "2025-03-09 04:00:00-0700", "Chg +1 hr" ],
                  [  7201, "2025-03-09 04:00:01-0700", "Chg +1 hr, 1 sec" ],
            );
    for (my $i = 0; $i < @spring; $i++) {
        is(POSIX::strftime("%F %T%z", localtime $t + $spring[$i][0]),
           $spring[$i][1], $spring[$i][2]);
    }
}
