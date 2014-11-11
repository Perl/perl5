use strict;
use warnings;

# On some threaded systems this test cannot be run.
BEGIN {
    require Test::Stream::Threads;
    if ($INC{'Carp.pm'}) {
        print "1..0 # SKIP: Carp is already loaded before we even begin.\n";
        exit 0;
    }
}

my @stack;
BEGIN {
    unshift @INC => sub {
        my ($ref, $filename) = @_;
        return if @stack;
        return unless $filename eq 'Carp.pm';
        my %seen;
        my $level = 1;
        while (my @call = caller($level++)) {
            my ($pkg, $file, $line) = @call;
            next if $seen{"$file $line"}++;
            push @stack => \@call;
        }
        return;
    };
}

use Test::More;

BEGIN {
    my $r = ok(!$INC{'Carp.pm'}, "Carp is not loaded when we start");
}

use ok 'Test::Stream::Carp', 'croak';

ok(!$INC{'Carp.pm'}, "Carp is not loaded");

if (@stack) {
    my $msg = "Carp load trace:\n";
    $msg .= "  $_->[1] line $_->[2]\n" for @stack;
    diag $msg;
}

my $out = eval { croak "xxx"; 1 };
my $err = $@;
ok(!$out, "died");
like($err, qr/xxx/, "Got carp exception");

ok($INC{'Carp.pm'}, "Carp is loaded now");

done_testing;
