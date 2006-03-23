use strict;
use warnings;

# test that END blocks are run in the thread that created them and
# not in any child threads

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    unless ($Config{'useithreads'}) {
        print "1..0 # Skip: no useithreads\n";
        exit 0;
    }
}

use ExtUtils::testlib;

BEGIN { print "1..6\n" };
use threads;
use threads::shared;

my $test_id = 1;
share($test_id);

sub ok {
    my ($ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    print $ok ? "ok $test_id - $name\n" : "not ok $test_id - $name\n";

    printf "# Failed test at line %d\n", (caller)[2] unless $ok;
    $test_id++;
    return $ok;
}
ok(1,'Loaded');
END { ok(1,"End block run once") }
threads->create(sub { eval "END { ok(1,'') }"})->join();
threads->create(sub { eval "END { ok(1,'') }"})->join();
threads->create(\&thread)->join();

sub thread {
	eval "END { ok(1,'') }";
	threads->create(sub { eval "END { ok(1,'') }"})->join();
}
