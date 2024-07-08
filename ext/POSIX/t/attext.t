use strict;
use warnings;

use Test::More tests => 4;
use POSIX qw(atexit);

pipe my $fr, my $fw;

my $child_pid = fork();
if ($child_pid) {
    close $fw;

    my $pid = wait();
    is $pid, $child_pid;

    my $out1 = <$fr>;
    is $out1, "child ${pid} exit (3)\n";

    my $out2 = <$fr>;
    is $out2, "child ${pid} exit (2)\n";

    my $out3 = <$fr>;
    is $out3, "child ${pid} exit (1)\n";
} else {
    close $fr;

    atexit(sub { print $fw "child $$ exit (1)\n" });
    atexit(sub { print $fw "child $$ exit (2)\n" });
    atexit(sub { print $fw "child $$ exit (3)\n" });
    exit(0);
}
