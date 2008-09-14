#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';

    require "./test.pl";
}

BEGIN {
    my $haslocal;
    eval { my $n = localtime 0 };
    $haslocal = 1 unless $@ && $@ =~ /unimplemented/;

    skip_all("no localtime") unless $haslocal;
}

BEGIN {
    my @localtime = CORE::localtime 0; # This is the function localtime.

    skip_all("localtime failed") unless @localtime;
}

BEGIN { plan tests => 37; }

BEGIN { use_ok Time::localtime; }

for my $time (0, 2**31-1, 2**33, time) {
    my $localtime = localtime $time;          # This is the OO localtime.
    my @localtime = CORE::localtime $time;    # This is the localtime function

    for my $method (qw(sec min hour mday mon year wday yday isdst)) {
        is $localtime->$method, shift @localtime, "localtime($time)->$method";
    }
}
