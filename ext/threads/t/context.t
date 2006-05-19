use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

use threads;
use threads::shared;

BEGIN {
    $| = 1;
    print("1..13\n");   ### Number of tests that will be run ###
};

my $TEST = 1;
share($TEST);

ok(1, 'Loaded');

sub ok {
    my ($ok, $name) = @_;

    lock($TEST);
    my $id = $TEST++;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}


### Start of Testing ###

sub foo
{
    my $context = shift;
    my $wantarray = wantarray();

    if ($wantarray) {
        ok($context eq 'array', 'Array context');
        return ('array');
    } elsif (defined($wantarray)) {
        ok($context eq 'scalar', 'Scalar context');
        return 'scalar';
    } else {
        ok($context eq 'void', 'Void context');
        return;
    }
}

my ($thr) = threads->create('foo', 'array');
my ($res) = $thr->join();
ok($res eq 'array', 'Implicit array context');

$thr = threads->create('foo', 'scalar');
$res = $thr->join();
ok($res eq 'scalar', 'Implicit scalar context');

threads->create('foo', 'void');
($thr) = threads->list();
$res = $thr->join();
ok(! defined($res), 'Implicit void context');

$thr = threads->create({'context' => 'array'}, 'foo', 'array');
($res) = $thr->join();
ok($res eq 'array', 'Explicit array context');

($thr) = threads->create({'scalar' => 'scalar'}, 'foo', 'scalar');
$res = $thr->join();
ok($res eq 'scalar', 'Explicit scalar context');

$thr = threads->create({'void' => 1}, 'foo', 'void');
$res = $thr->join();
ok(! defined($res), 'Explicit void context');

# EOF
