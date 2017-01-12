use strict;
use warnings;

BEGIN {
    require($ENV{PERL_CORE} ? '../../t/test.pl' : './t/test.pl');

    use Config;
    if (! $Config{'useithreads'}) {
        skip_all(q/Perl not compiled with 'useithreads'/);
    }
}

use ExtUtils::testlib;
use Cwd;
my $cwd = cwd();

use threads;

BEGIN {
    if (! eval 'use threads::shared; 1') {
        skip_all('threads::shared not available');
    }

    local $SIG{'HUP'} = sub {};
    my $thr = threads->create(sub {});
    eval { $thr->kill('HUP') };
    $thr->join();
    if ($@ && $@ =~ /safe signals/) {
        skip_all('Not using safe signals');
    }

    plan(2);
};

{
    $SIG{'KILL'} = undef;
    chdir '/tmp';
    mkdir "toberead$$";
    chdir "toberead$$";
    for ('a'..'e') {
        open my $THING, ">$_";
        close $THING or die "$_: $!";
    }
    chdir $cwd;

    local $ARGV[0] = undef;
    fresh_perl_is(<<'EOI', 'ok', { }, 'RT #77934: Case: Perl-false $ARGV[0]');
    local $@;
    my $DIRH;
    my $thr;
    $thr = async {
        # Thread 'cancellation' signal handler
        $SIG{'KILL'} = sub { threads->exit(); };

        opendir $DIRH, ".";
        my $start = telldir $DIRH;
        while (1) {
            readdir $DIRH or seekdir $DIRH, 0;
        }
    } if $ARGV[0];

    opendir $DIRH, ".";
    for(1..5) {
        select undef, undef, undef, .25;
    }

    if ($ARGV[0]) {
        $thr->kill('KILL')->detach();
    }
    print($@ ? 'not ok' : 'ok');
EOI
}

{
    $SIG{'KILL'} = undef;
    chdir '/tmp';
    mkdir "shouldberead$$";
    chdir "shouldberead$$";
    for ('a'..'e') {
        open my $THING, ">$_";
        close $THING or die "$_: $!";
    }
    chdir $cwd;

    local $ARGV[0] = 1;
    fresh_perl_is(<<'EOI', 'ok', { }, 'RT #77934: Case: Perl-true  $ARGV[0]');
    local $@;
    my $DIRH;
    my $thr;
    $thr = async {
        # Thread 'cancellation' signal handler
        $SIG{'KILL'} = sub { threads->exit(); };

        opendir $DIRH, ".";
        my $start = telldir $DIRH;
        while (1) {
            readdir $DIRH or seekdir $DIRH, 0;
        }
    } if $ARGV[0];

    opendir $DIRH, ".";
    for(1..5) {
        select undef, undef, undef, .25;
    }

    if ($ARGV[0]) {
        $thr->kill('KILL')->detach();
    }
    print($@ ? 'not ok' : 'ok');
EOI
}

exit(0);
