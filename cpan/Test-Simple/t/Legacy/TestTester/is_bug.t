use strict;
use warnings;
use Test::Tester;
use Test::More;

check_test(
    sub { is "Foo", "Foo" },
    {ok => 1},
);

check_test(
    sub { is "Bar", "Bar" },
    {ok => 1},
);

check_test(
    sub { is "Baz", "Quux" },
    {ok => 0},
);

check_test(
    sub { like "Baz", qr/uhg/ },
    {ok => 0},
);

check_test(
    sub { like "Baz", qr/a/ },
    {ok => 1},
);

done_testing();
