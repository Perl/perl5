use strict;
use warnings;

BEGIN {
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
}

use ExtUtils::testlib;

sub ok {
    my ($id, $ok, $name) = @_;

    # You have to do it this way or VMS will get confused.
    if ($ok) {
        print("ok $id - $name\n");
    } else {
        print("not ok $id - $name\n");
        printf("# Failed test at line %d\n", (caller)[2]);
    }

    return ($ok);
}

sub is {
    my ($id, $got, $expected, $name) = @_;

    my $ok = ok($id, $got == $expected, $name);
    if (! $ok) {
        print("     GOT: $got\n");
        print("EXPECTED: $expected\n");
    }

    return ($ok);
}

BEGIN {
    $| = 1;
    print("1..18\n");   ### Number of tests that will be run ###
};

use threads ('stack_size' => 128*4096);
ok(1, 1, 'Loaded');

### Start of Testing ###

is(2, threads->get_stack_size(), 128*4096,
        'Stack size set in import');
is(3, threads->set_stack_size(160*4096), 128*4096,
        'Set returns previous value');
is(4, threads->get_stack_size(), 160*4096,
        'Get stack size');

threads->create(
    sub {
        is(5, threads->get_stack_size(), 160*4096,
                'Get stack size in thread');
        is(6, threads->self()->get_stack_size(), 160*4096,
                'Thread gets own stack size');
        is(7, threads->set_stack_size(128*4096), 160*4096,
                'Thread changes stack size');
        is(8, threads->get_stack_size(), 128*4096,
                'Get stack size in thread');
        is(9, threads->self()->get_stack_size(), 160*4096,
                'Thread stack size unchanged');
    }
)->join();

is(10, threads->get_stack_size(), 128*4096,
        'Default thread sized changed in thread');

threads->create(
    { 'stack' => 160*4096 },
    sub {
        is(11, threads->get_stack_size(), 128*4096,
                'Get stack size in thread');
        is(12, threads->self()->get_stack_size(), 160*4096,
                'Thread gets own stack size');
    }
)->join();

my $thr = threads->create( { 'stack' => 160*4096 }, sub { } );

$thr->create(
    sub {
        is(13, threads->get_stack_size(), 128*4096,
                'Get stack size in thread');
        is(14, threads->self()->get_stack_size(), 160*4096,
                'Thread gets own stack size');
    }
)->join();

$thr->create(
    { 'stack' => 144*4096 },
    sub {
        is(15, threads->get_stack_size(), 128*4096,
                'Get stack size in thread');
        is(16, threads->self()->get_stack_size(), 144*4096,
                'Thread gets own stack size');
        is(17, threads->set_stack_size(160*4096), 128*4096,
                'Thread changes stack size');
    }
)->join();

$thr->join();

is(18, threads->get_stack_size(), 160*4096,
        'Default thread sized changed in thread');

exit(0);

# EOF
