#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';

    require "./test.pl";
}

BEGIN { plan tests => 37; }

BEGIN { use_ok Time::gmtime; }

# Perl has its own gmtime() so it's safe to do negative times.
for my $time (-2**33, -2**31-1, 0, 2**31-1, 2**33, time) {
    my $gmtime = gmtime $time;          # This is the OO gmtime.
    my @gmtime = CORE::gmtime $time;    # This is the gmtime function

    for my $method (qw(sec min hour mday mon year wday yday isdst)) {
        is $gmtime->$method, shift @gmtime, "gmtime($time)->$method";
    }
}
