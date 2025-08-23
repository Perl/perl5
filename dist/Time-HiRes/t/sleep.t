use strict;

use Test::More tests => 5;
BEGIN { push @INC, '.' }
use t::Watchdog;

BEGIN { require_ok "Time::HiRes"; }

use Config;

SKIP: {
    skip "no hi-res sleep", 1 unless defined &Time::HiRes::sleep;
    is prototype(\&Time::HiRes::sleep), prototype('CORE::sleep'),
        "Time::HiRes::sleep's prototype matches CORE::sleep's";
}

my $xdefine = '';
if (open(my $fh, "<", "xdefine")) {
    chomp($xdefine = <$fh> || "");
    close($fh);
}

my $can_subsecond_alarm =
   defined &Time::HiRes::gettimeofday &&
   defined &Time::HiRes::ualarm &&
   defined &Time::HiRes::usleep &&
   ($Config{d_ualarm} || $xdefine =~ /-DHAS_UALARM/);

eval { Time::HiRes::sleep(-1) };
like $@, qr/::sleep\(-1\): negative time not invented yet/,
        "negative time error";

SKIP: {
    skip "no subsecond alarm", 2 unless $can_subsecond_alarm;
    my $f = Time::HiRes::time;
    print("# time...$f\n");
    ok 1;

    my $r = [Time::HiRes::gettimeofday()];
    Time::HiRes::sleep (0.5);
    printf("# sleep...%s\n", Time::HiRes::tv_interval($r));
    ok 1;
}
