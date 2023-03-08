#!perl
use strict;
use warnings;

my $target = shift
    or die usage();

my $latest = (stat $target)[9]
    or die "$0: Target $target not found: $!\n";
for my $source (@ARGV) {
    my @st = stat $source;
    $st[9] > $latest and $latest = $st[9];
}

utime($latest, $latest, $target)
    or die "Couldn't update modification time of $target: $!\n";

sub usage {
    <<EOS;
Usage: $0 target sourcefiles...
  Sets the modification time of target to the latest time out of
  the target and all the source files.
EOS
}
