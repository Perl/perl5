use strict;
use warnings;

use Test::More;

use ok 'Test::Stream::Block';

our %BLOCKS;
our %STARTS;
our %ENDS;

is(keys %BLOCKS, 6, "created 6 blocks");

isa_ok($_, 'Test::Stream::Block') for values %BLOCKS;

is($BLOCKS{one}->start_line, $STARTS{one},     "got start line for block one");
is($BLOCKS{one}->end_line,   $STARTS{two} - 1, "got end line for block one");

is($BLOCKS{two}->start_line, $STARTS{two}, "got start line for block two");
is($BLOCKS{two}->end_line,   $ENDS{two},   "got end line for block two");

ok($BLOCKS{three}->start_line > $ENDS{two},  "got start line for block three");
ok($BLOCKS{three}->end_line < $STARTS{four}, "got end line for block three");

is($BLOCKS{four}->start_line, $STARTS{four}, "got start line for block four");
is($BLOCKS{four}->end_line,   $STARTS{four}, "got end line for block four");

is($BLOCKS{five}->start_line, $STARTS{five}, "got start line for block five");
is($BLOCKS{five}->end_line,   $ENDS{EOF},    "got end line for block five");

is(
    $BLOCKS{one}->detail,
    'one (block_one) in ' . __FILE__ . " lines $STARTS{one} -> " . ($STARTS{two} - 1),
    "Got expected detail for multiline"
);

is(
    $BLOCKS{four}->detail,
    'four in ' . __FILE__ . " line $STARTS{four}",
    "Got expected detail for single line"
);

like(
    $BLOCKS{foo}->detail,
    qr/foo \(foo\) in \(eval \d+\) line 2 \(declared in \(eval \d+\) line 1\)/,
    "Got expected detail for endless sub"
);

done_testing;

BEGIN {
    package TheTestPackage;

    sub build_block {
        my $name = shift;
        my $code = pop;
        my %params = @_;
        my @caller = caller;

        $main::BLOCKS{$name} = Test::Stream::Block->new_from_pairs(
            name    => $name,
            params  => \%params,
            coderef => $code,
            caller  => \@caller,
        );
    }

    build_block five => \&block_five;

    BEGIN {$main::STARTS{one} = __LINE__ + 1}
    sub block_one {
        my $x = 1;
        my $y = 1;
        return "one: " . $x + $y;
    }

    build_block two => sub {
        my $x = 1; BEGIN {$main::STARTS{two} = __LINE__ - 1}
        my $y = 1;
        return "three: " . $x + $y;
    };
    BEGIN {$main::ENDS{two} = __LINE__ - 1}

    sub block_three { return "three: 2" } BEGIN {$main::STARTS{three} = __LINE__}

    BEGIN {$main::STARTS{four} = __LINE__ + 1}
    build_block four => sub { return "four: 2" };

    BEGIN {$main::STARTS{five} = __LINE__ + 1}
    sub block_five {
        my $x = 1;
        my $y = 1;
        return "five: " . $x + $y;
    }

    build_block one   => \&block_one;
    build_block three => (this_is => 3, \&block_three);

    package Foo;
    eval <<'    EOT' || die $@;
        TheTestPackage::build_block foo => \&foo;
        sub foo {
            'foo'
        };
        1
    EOT
}
BEGIN {$main::ENDS{EOF} = __LINE__}
