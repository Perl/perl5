use strict;
use warnings;

use Config;

BEGIN {
    if (! $Config{'useithreads'}) {
        print("1..0 # SKIP Perl not compiled with 'useithreads'\n");
        exit(0);
    }
    if (! $Config{'d_select'}) {
        print("1..0 # SKIP 'select()' not available for testing\n");
        exit(0);
    }
}

use threads;
use Thread::Queue;

use Test::More;

plan tests => 8;

my $q = Thread::Queue->new();
my $rpt = Thread::Queue->new();

my $th = threads->create( sub {
    # (1) Set queue limit, and report it
    $q->limit = 3;
    $rpt->enqueue($q->limit);

    # (3) Fetch an item from queue
    my $item = $q->dequeue();
    is($item, 1, 'Dequeued item 1');
    # Report queue count
    $rpt->enqueue($q->pending());

    # q = (2, 3, 4, 5); r = (4)

    # (4) Enqueue more items - will block
    $q->enqueue(6, 7);
    # q = (5, 'foo', 6, 7); r = (4, 3, 4, 3)

    # (6) Get reports from main
    my @items = $rpt->dequeue(5);
    is_deeply(\@items, [4, 3, 4, 3, 'go'], 'Queue reports');

    # Dequeue all items
    @items = $q->dequeue_nb(99);
    is_deeply(\@items, [5, 'foo', 6, 7], 'Queue items');
});

# (2) Read queue limit from thread
my $item = $rpt->dequeue();
is($item, $q->limit, 'Queue limit set');
# Send items
$q->enqueue(1, 2, 3, 4, 5);

# (5) Read queue count
$item = $rpt->dequeue;
# q = (2, 3, 4, 5); r = ()
is($item, $q->pending(), 'Queue count');
# Report back the queue count
$rpt->enqueue($q->pending);
# q = (2, 3, 4, 5); r = (4)

# Read an item from queue
$item = $q->dequeue();
is($item, 2, 'Dequeued item 2');
# q = (3, 4, 5); r = (4)
# Report back the queue count
$rpt->enqueue($q->pending);
# q = (3, 4, 5); r = (4, 3)

# 'insert' doesn't care about queue limit
$q->insert(3, 'foo');
$rpt->enqueue($q->pending);
# q = (3, 4, 5, 'foo'); r = (4, 3, 4)

# Read an item from queue
$item = $q->dequeue();
is($item, 3, 'Dequeued item 3');
# q = (3, 4, 5); r = (4)
# Report back the queue count
$rpt->enqueue($q->pending);
# q = (4, 5, 'foo'); r = (4, 3, 4, 3)

# Read an item from queue
$item = $q->dequeue();
is($item, 4, 'Dequeued item 4');
# Thread is now unblocked

# Handshake with thread
$rpt->enqueue('go');

# (7) - Done
$th->join;

exit(0);

# EOF
