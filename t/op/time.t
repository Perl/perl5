#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 32;

($beguser,$begsys) = times;

$beg = time;

while (($now = time) == $beg) { sleep 1 }

ok($now > $beg && $now - $beg < 10,             'very basic time test');

for ($i = 0; $i < 1_000_000; $i++) {
    for my $j (1..100) {}; # burn some user cycles
    ($nowuser, $nowsys) = times;
    $i = 2_000_000 if $nowuser > $beguser && ( $nowsys >= $begsys ||
                                            (!$nowsys && !$begsys));
    last if time - $beg > 20;
}

ok($i >= 2_000_000, 'very basic times test');

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($beg);
($xsec,$foo) = localtime($now);
$localyday = $yday;

isnt($sec, $xsec),      'localtime() list context';
ok $mday,               '  month day';
ok $year,               '  year';

ok(localtime() =~ /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                    (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                    ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})$
                  /x,
   'localtime(), scalar context'
  );

SKIP: {
    # This conditional of "No tzset()" is stolen from ext/POSIX/t/time.t
    skip "No tzset()", 1
        if $^O eq "MacOS" || $^O eq "VMS" || $^O eq "cygwin" ||
           $^O eq "djgpp" || $^O eq "MSWin32" || $^O eq "dos" ||
           $^O eq "interix";

# check that localtime respects changes to $ENV{TZ}
$ENV{TZ} = "GMT-5";
($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($beg);
$ENV{TZ} = "GMT+5";
($sec,$min,$hour2,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($beg);
ok($hour != $hour2,                             'changes to $ENV{TZ} respected');
}


($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime($beg);
($xsec,$foo) = localtime($now);

isnt($sec, $xsec),      'gmtime() list conext';
ok $mday,               '  month day';
ok $year,               '  year';

my $day_diff = $localyday - $yday;
ok( grep({ $day_diff == $_ } (0, 1, -1, 364, 365, -364, -365)),
                     'gmtime() and localtime() agree what day of year');


# This could be stricter.
ok(gmtime() =~ /^(Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
                 (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
                 ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4})$
               /x,
   'gmtime(), scalar context'
  );



# Test gmtime over a range of times.
{
    # gm/localtime is limited by the size of tm_year which might be as small as 16 bits
    my %tests = (
        # time_t         gmtime list                          scalar
        -2**35        => [52, 13, 20, 7, 2, -1019, 5, 65, 0, "Fri Mar  7 20:13:52 881"],
        -2**32        => [44, 31, 17, 24, 10, -67, 0, 327, 0, "Sun Nov 24 17:31:44 1833"],
        -2**31        => [52, 45, 20, 13, 11, 1, 5, 346, 0, "Fri Dec 13 20:45:52 1901"],
        0             => [0, 0, 0, 1, 0, 70, 4, 0, 0, "Thu Jan  1 00:00:00 1970"],
        2**30         => [4, 37, 13, 10, 0, 104, 6, 9, 0, "Sat Jan 10 13:37:04 2004"],
        2**31         => [8, 14, 3, 19, 0, 138, 2, 18, 0, "Tue Jan 19 03:14:08 2038"],
        2**32         => [16, 28, 6, 7, 1, 206, 0, 37, 0, "Sun Feb  7 06:28:16 2106"],
        2**39         => [8, 18, 12, 25, 0, 17491, 2, 24, 0, "Tue Jan 25 12:18:08 19391"],
    );

    for my $time (keys %tests) {
        my @expected  = @{$tests{$time}};
        my $scalar    = pop @expected;

        ok eq_array([gmtime($time)], \@expected),  "gmtime($time) list context";
        is scalar gmtime($time), $scalar,       "  scalar";
    }
}


# Test localtime
{
    # We pick times which fall in the middle of a month, so the month and year should be
    # the same regardless of the time zone.
    my %tests = (
        # time_t           month, year,  scalar
        5000000000      => [5,  228,     qr/Jun \d+ .* 2128$/],
        1163500000      => [10, 106,     qr/Nov \d+ .* 2006$/],
    );

    for my $time (keys %tests) {
        my @expected  = @{$tests{$time}};
        my $scalar    = pop @expected;

        ok eq_array([(localtime($time))[4,5]], \@expected),  "localtime($time) list context";
        like scalar localtime($time), $scalar,       "  scalar";
    }
}
