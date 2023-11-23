#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = ('../lib');
    require Config; Config->import;
    require './test.pl';
    skip_all_if_miniperl("No XS modules under miniperl");
}

use strict;
use warnings;

# test this many times to try to avoid noise from othe processes
my $trial_count = 3;

use List::Util qw(min);

my %basetimes;
# need around 1e6 for the O(n**2) behaviour to really kick in
my $small_size = 50_000;
my $large_size = 1_000_000;

for my $size ($small_size, $large_size) {
    for my $j (1 .. $trial_count) {
        my $time = fresh_perl(<<'CODE', { args => [ $size ] });
use strict;
use Time::HiRes qw(time);

my $size = shift;
my $s = (join " ", 0 .. 9) . "\n";
$s x= $size;
my @x;
my $start = time;
@x = $s =~ /(.*?\n|.+)/gs;
@x == $size or die;
print time() - $start;
CODE
        is($?, 0, "size $size run $j success");
        like($time, qr/^[\d.]+(?:e-?\d+)?\n?$/, "size $size run $j result valid");
        chomp $time;
        push $basetimes{$size}->@*, $time;
        note "size $size run $j result $time";
    }
}

my $min_small = min($basetimes{$small_size}->@*);
my $min_large = min($basetimes{$large_size}->@*);
my $ratio = $large_size / $small_size;

my $worst = $min_small * $ratio * 2;
note "worst allowed $worst";
cmp_ok($min_large, '<', $worst,
       "check growing the tmps stack takes O(n) time");

done_testing();
