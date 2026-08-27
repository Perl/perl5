use strict;
use warnings;

use Test2::V0;
use Test2::Compare qw/compare strict_convert/;

my $ARRAY_ERROR = "'end' with no items specified requires an empty array, which discards the 'all_items' checks; use 'etc' instead of 'end' to check every item without bounding the array";
my $BAG_ERROR   = "'end' with no items specified requires an empty bag, which discards the 'all_items' checks; use 'etc' instead of 'end' to check every item without bounding the bag";
my $HASH_ERROR  = "'end' with no fields specified requires an empty hash, which discards the 'all_keys' and 'all_values' checks; use 'etc' instead of 'end' to check every key and value without bounding the hash";

subtest empty_specification_is_an_error => sub {
    my $file = __FILE__;

    my $array_line = __LINE__ + 2;
    my $array_err  = dies {
        my $check = array {
            all_items match qr/x/;
            end();
        };
    };
    is($array_err, "$ARRAY_ERROR at $file line $array_line.\n", "array with only all_items and end is rejected");

    my $bag_line = __LINE__ + 2;
    my $bag_err  = dies {
        my $check = bag {
            all_items match qr/x/;
            end();
        };
    };
    is($bag_err, "$BAG_ERROR at $file line $bag_line.\n", "bag with only all_items and end is rejected");

    my $vals_line = __LINE__ + 2;
    my $vals_err  = dies {
        my $check = hash {
            all_vals match qr/x/;
            end();
        };
    };
    is($vals_err, "$HASH_ERROR at $file line $vals_line.\n", "hash with only all_vals and end is rejected");

    my $keys_line = __LINE__ + 2;
    my $keys_err  = dies {
        my $check = hash {
            all_keys match qr/x/;
            end();
        };
    };
    is($keys_err, "$HASH_ERROR at $file line $keys_line.\n", "hash with only all_keys and end is rejected");

    like(
        dies { my $check = hash { all_keys match qr/x/; all_vals match qr/x/; end() } },
        qr/^\Q$HASH_ERROR\E at /,
        "hash using both all_keys and all_vals is rejected"
    );
};

subtest exception_does_not_depend_on_builder_order => sub {
    like(
        dies { my $check = array { end(); all_items match qr/x/ } },
        qr/^\Q$ARRAY_ERROR\E at /,
        "end before all_items is still rejected"
    );

    like(
        dies { my $check = array { all_items match qr/x/; end(); all_items match qr/y/ } },
        qr/^\Q$ARRAY_ERROR\E at /,
        "all_items on both sides of end is still rejected"
    );

    like(
        dies { my $check = array { filter_items { grep { !m/[0-9]/ } @_ }; all_items match qr/x/; end() } },
        qr/^\Q$ARRAY_ERROR\E at /,
        "a filter does not count as specifying an item"
    );

    like(
        dies { my $check = array { all_items match qr/x/, match qr/y/; end() } },
        qr/^\Q$ARRAY_ERROR\E at /,
        "multiple checks in one all_items call are still rejected"
    );
};

subtest builds_that_must_not_throw => sub {
    ok(lives { my $check = array {all_items match qr/x/} },  "all_items with no end or etc is fine");
    ok(lives { my $check = array {all_items match qr/x/; etc()} }, "all_items with etc is fine");
    ok(lives { my $check = array {item 0 => 'a'; all_items match qr/x/; end()} }, "all_items with an item and end is fine");
    ok(lives { my $check = array {end()} }, "end with no all_items is fine");
    ok(lives { my $check = array {item 0 => 'a'; end()} }, "end with an item is fine");
    ok(lives { my $check = bag {all_items match qr/x/; etc()} }, "bag all_items with etc is fine");
    ok(lives { my $check = bag {item 'a'; all_items match qr/x/; end()} }, "bag all_items with an item and end is fine");
    ok(lives { my $check = bag {end()} }, "bag end with no all_items is fine");
    ok(lives { my $check = hash {all_vals match qr/x/; etc()} }, "hash all_vals with etc is fine");
    ok(lives { my $check = hash {field a => 1; all_keys match qr/x/; end()} }, "hash all_keys with a field and end is fine");
    ok(lives { my $check = hash {end()} }, "hash end with no all_keys or all_vals is fine");
    ok(lives { my $check = object {call foo => 1} }, "a builder with no verify_build override is fine");
};

subtest etc_checks_every_item => sub {
    is([1, 2, 3], array {all_items match qr/^\d+$/; etc()}, "every array item checked, length unbounded");
    is([1, 2, 3], bag   {all_items match qr/^\d+$/; etc()}, "every bag item checked, length unbounded");
    is({a => 1, b => 2}, hash {all_keys match qr/^\w$/; all_vals match qr/^\d+$/; etc()}, "every hash key and value checked");

    isnt([1, 'a'], array {all_items match qr/^\d+$/; etc()}, "a bad item still fails");
    isnt([1, 'a'], bag   {all_items match qr/^\d+$/; etc()}, "a bad bag item still fails");
    isnt({a => 'x'}, hash {all_vals match qr/^\d+$/; etc()}, "a bad value still fails");
};

subtest end_still_bounds_when_items_are_specified => sub {
    is(
        ['a', 'bb'],
        array {item 0 => 'a'; item 1 => 'bb'; all_items match qr/^[a-z]+$/; end()},
        "array with items, all_items, and end passes when the length matches"
    );

    isnt(
        ['a', 'bb', 'ccc'],
        array {item 0 => 'a'; item 1 => 'bb'; all_items match qr/^[a-z]+$/; end()},
        "array end still rejects an extra item when all_items is used"
    );

    is(
        ['bb', 'a'],
        bag {item 'a'; item 'bb'; all_items match qr/^[a-z]+$/; end()},
        "bag with items, all_items, and end passes when the length matches"
    );

    isnt(
        ['bb', 'a', 'ccc'],
        bag {item 'a'; item 'bb'; all_items match qr/^[a-z]+$/; end()},
        "bag end still rejects an extra item when all_items is used"
    );

    is(
        {a => 'a', b => 'bb'},
        hash {field a => 'a'; field b => 'bb'; all_vals match qr/^[a-z]+$/; end()},
        "hash with fields, all_vals, and end passes when the fields match"
    );

    isnt(
        {a => 'a', b => 'bb', c => 'ccc'},
        hash {field a => 'a'; field b => 'bb'; all_vals match qr/^[a-z]+$/; end()},
        "hash end still rejects an extra field when all_vals is used"
    );
};

subtest implicit_end_still_bounds_all_items_checks => sub {
    # is() applies its implicit end by cloning the check when it converts it, long
    # after the builder block ran, so this path is invisible to the build-time check.
    my $unverified = sub {
        my @todo = @_;
        my @found;
        while (my $delta = shift @todo) {
            my $children = $delta->children;
            push @todo  => @$children if $children && @$children;
            push @found => $delta unless $delta->verified;
        }
        return \@found;
    };

    my $bag = $unverified->(compare([1, 2, 3], bag {all_items match qr/^\d+$/}, \&strict_convert));
    is(
        [map { [$_->id->[1], $_->note] } @$bag],
        [[0, 'implicit end'], [1, 'implicit end'], [2, 'implicit end']],
        "a bag using all_items is bounded by the implicit end"
    );

    my $array = $unverified->(compare([1, 2, 3], array {all_items match qr/^\d+$/}, \&strict_convert));
    is(
        [map { [$_->id->[1], $_->note] } @$array],
        [[0, 'implicit end'], [1, 'implicit end'], [2, 'implicit end']],
        "an array using all_items is bounded the same way"
    );
};

done_testing;
