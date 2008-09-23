#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';

    require "./test.pl";
}

my(@times, @methods);
BEGIN {
    @times   = (-2**33, -2**31-1, 0, 2**31-1, 2**33, time);
    @methods = qw(sec min hour mday mon year wday yday isdst);

    plan tests => (@times * @methods) + 1;

    use_ok Time::gmtime;
}

# Perl has its own gmtime() so it's safe to do negative times.
for my $time (@times) {
    my $gmtime = gmtime $time;          # This is the OO gmtime.
    my @gmtime = CORE::gmtime $time;    # This is the gmtime function

    for my $method (@methods) {
        is $gmtime->$method, shift @gmtime, "gmtime($time)->$method";
    }
}
