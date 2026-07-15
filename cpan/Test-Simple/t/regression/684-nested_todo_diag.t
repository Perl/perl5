use Test::More;
use strict;
use warnings;

# Detect the line numbering behaviour of this version of perl
our $use_block_end;
BEGIN {
    sub X { my (undef, undef, $line) = caller;
            $use_block_end++ if ($line != shift);
    }
    X __LINE__, # $use_block_end = 0
    sub { }     # $use_block_end = 1
}

use Test2::API qw/intercept/;
my @events;

intercept {
    local $TODO = "broken";

    Test2::API::test2_stack->top->listen(sub { push @events => $_[1] }, inherit => 1);

    subtest foo => sub {
        subtest bar => sub {
            ok(0, 'oops');
        };
    };
};

my $target_line = ($use_block_end) ? 26 : 23;

my ($event) = grep { $_->trace->line == $target_line && ref($_) eq 'Test::Builder::TodoDiag'} @events;
ok($event, "nested todo diag on line $target_line was changed to TodoDiag (STDOUT instead of STDERR)");

done_testing;
