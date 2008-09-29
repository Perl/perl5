#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';

    require "./test.pl";
}

BEGIN {
    @times   = (-2**33, -2**31-1, 0, 2**31-1, 2**33, time);
    @methods = qw(sec min hour mday mon year wday yday isdst);

    plan tests => (@times * @methods) + 1;

    use_ok Time::localtime;
}

# Since Perl's localtime() still uses the system localtime, don't try
# to do negative times.  The system might not support it.
for my $time (@times) {
    my $localtime = localtime $time;          # This is the OO localtime.
    my @localtime = CORE::localtime $time;    # This is the localtime function

    for my $method (@methods) {
        is $localtime->$method, shift @localtime, "localtime($time)->$method";
    }
}
