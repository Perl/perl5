#!/usr/bin/perl -w

BEGIN {
  chdir 't';
  @INC = '../lib';
  require './test.pl';
  skip_all_without_dynamic_extension("Devel::Peek");
}

use strict;
use Devel::Peek;
use File::Temp qw(tempdir);

my %hash = map +($_ => 1), ("a".."z");

my $tmp_dir = tempdir(CLEANUP => 1);

sub riter {
    local *OLDERR;
    open(OLDERR, ">&STDERR") || die "Can't dup STDERR: $!";
    open(STDERR, ">", "$tmp_dir/dump") ||
        die "Could not open '$tmp_dir/dump' for write: $^E";
    Dump(\%hash);
    open(STDERR, ">&OLDERR") || die "Can't dup OLDERR: $!";
    open(my $fh, "<", "$tmp_dir/dump") ||
        die "Could not open '$tmp_dir/dump' for read: $^E";
    local $/;
    my $dump = <$fh>;
    my ($riter) = $dump =~ /^\s*RITER\s*=\s*(\d+)/m or
        die "No plain RITER in dump '$dump'";
    return $riter;
}

my @riters;
while (my $key = each %hash) {
    push @{$riters[riter()]}, $key;
}

my ($first_key, $second_key);
my $riter = 0;
for my $chain (@riters) {
    if ($chain && @$chain >= 2) {
        $first_key  = $chain->[0];
        $second_key = $chain->[1];
        last;
    }
    $riter++;
}
$first_key ||
    skip_all "No 2 element chains; need a different initial HASH";
$| = 1;

plan(1);

# Ok all preparation is done
diag <<"EOF"
Found keys '$first_key' and '$second_key' on chain $riter
Will now iterato to key '$first_key' then delete '$first_key' and '$second_key'.
EOF
;
1 until $first_key eq each %hash;
delete $hash{$first_key};
delete $hash{$second_key};

diag "Now iterating into freed memory\n";
1 for each %hash;
ok(1, "Survived!");
