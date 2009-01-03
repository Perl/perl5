#!perl
#
# given a perforce change number, checkout the equivalent git commit
# into the git working directory
#
use strict;
use warnings;
use English;

my $perforce_id = shift;
die "Usage: switch_to_perforce_id.pl 34440" unless $perforce_id;

open my $fh, 'git log -z --pretty=raw|' or die $!;
local $INPUT_RECORD_SEPARATOR = "\0";

my $re = qr/p4raw-id:.+\@$perforce_id/;

while ( my $log = <$fh> ) {
    next unless $log =~ /$re/;
    my ($commit) = $log =~ /commit ([a-z0-9]+)/;
    system "git checkout $commit";
    print "(use git checkout blead to go back)\n";
    exit;
}

die "No log found for $perforce_id";
