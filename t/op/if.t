#!./perl -w

chdir 't' if -d 't';
require './test.pl';
set_up_inc('../lib');

use strict;

$|=1;

run_multiple_progs('', \*DATA);

done_testing();

__DATA__
# GH #22204
package foo;
sub new {
    return bless {}, 'foo';
}

sub DESTROY {
    $main::status = "Finished";
}

package main;
for (0..1) {
    $status = "Started";
    print $status, "\n";
    if ($_) {
        my $magic = foo->new();
    } else {
        my $magic = foo->new();
    }
    print "  $status\n";
}
print "$status\n";
EXPECT
Started
  Finished
Started
  Finished
Finished
########
# GH #23175
sub bogocarp() { my ($fi, $pa, $line) = caller; die("$line should have been 5"); }
my $gr = 1;
if ($gr) {
  bogocarp();
}
EXPECT
5 should have been 5 at - line 2.
########
# GH #12573
my $something;
if( ! $something )
{
die("Hi from line ".__LINE__);
}
EXPECT
Hi from line 5 at - line 5.

