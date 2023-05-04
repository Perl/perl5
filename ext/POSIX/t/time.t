#!perl -w

BEGIN {
    unshift @INC, "../../t";
    require 'loc_tools.pl';
}

use strict;

use Config;
use POSIX;
use Test::More tests => 20;

# go to UTC to avoid DST issues around the world when testing.  SUS3 says that
# null should get you UTC, but some environments want the explicit names.
# Those with a working tzset() should be able to use the TZ below.
$ENV{TZ} = "UTC0UTC";

SKIP: {
    # It looks like POSIX.xs claims that only VMS and Mac OS traditional
    # don't have tzset().  Win32 works to call the function, but it doesn't
    # actually do anything.  Cygwin works in some places, but not others.  The
    # other Win32's below are guesses.
    skip "No tzset()", 2
       if $^O eq "VMS" || $^O eq "cygwin" ||
          $^O eq "MSWin32" || $^O eq "interix";
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

# Careful!  strftime() is locale sensitive.  Let's take care of that
my $orig_time_loc = 'C';
my $orig_ctype_loc = 'C';
if (locales_enabled('LC_TIME')) {
    $orig_time_loc = setlocale(LC_TIME) || die "Cannot get time locale information:  $!";
    setlocale(LC_TIME, "C") || die "Cannot setlocale() to C:  $!";
}
my $jan_16 = 15 * 86400;
is(ctime($jan_16), strftime("%a %b %d %H:%M:%S %Y\n", CORE::localtime($jan_16)),
        "get ctime() equal to strftime()");
is(ctime($jan_16), strftime("%a %b %d %H:%M:%S %Y\n", POSIX::localtime($jan_16)),
        "get ctime() equal to strftime()");

my $ss = chr 223;
unlike($ss, qr/\w/, 'Not internally UTF-8 encoded');
is(ord strftime($ss, CORE::localtime), 223,
   'Format string has correct character');
is(ord strftime($ss, POSIX::localtime(time)),
   223, 'Format string has correct character');
unlike($ss, qr/\w/, 'Still not internally UTF-8 encoded');

my $zh_format = "%Y\x{5e74}%m\x{6708}%d\x{65e5}";
my $zh_expected_result = "1970\x{5e74}01\x{6708}16\x{65e5}";
TODO: {
    local $TODO = 'Awaiting more fixes';
    ok(strftime($zh_format, CORE::gmtime($jan_16)) ne $zh_expected_result,
           "strftime() UTF-8 format doesn't return UTF-8 in non-UTF-8 locale");
}

my $utf8_locale = find_utf8_ctype_locale();
SKIP: {
    skip "No UTF-8 locale", 2 if ! defined $utf8_locale;

    setlocale(LC_TIME, $utf8_locale)
                               || die "Cannot setlocale() to $utf8_locale: $!";
    # By setting LC_TIME only, we verify that the code properly handles the
    # case where that and LC_CTYPE differ
    is(strftime($zh_format, CORE::gmtime($jan_16)),
                $zh_expected_result,
                "strftime() can handle a UTF-8 format;  LC_CTYPE != LCTIME");
    is(strftime($zh_format, POSIX::gmtime($jan_16)),
                $zh_expected_result,
                "Same, but uses POSIX::gmtime; previous test used CORE::");
}

if (locales_enabled('LC_TIME')) {
    setlocale(LC_TIME, $orig_time_loc) || die "Cannot setlocale(LC_TIME) back to orig: $!";
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
