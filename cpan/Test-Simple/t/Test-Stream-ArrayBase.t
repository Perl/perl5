use strict;
use warnings;

use Test::More;
use lib 'lib';

BEGIN {
    $INC{'My/ABase.pm'} = __FILE__;

    package My::ABase;
    use Test::Stream::ArrayBase(
        accessors => [qw/foo bar baz/],
    );

    use Test::More;
    is(FOO, 0, "FOO CONSTANT");
    is(BAR, 1, "BAR CONSTANT");
    is(BAZ, 2, "BAZ CONSTANT");

    my $bad = eval { Test::Stream::ArrayBase->import( accessors => [qw/foo/] ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/field 'foo' already defined/, "Expected error");
}

BEGIN {
    package My::ABaseSub;
    use Test::Stream::ArrayBase(
        accessors => [qw/apple pear/],
        base      => 'My::ABase',
    );

    use Test::More;
    is(FOO,   0, "FOO CONSTANT");
    is(BAR,   1, "BAR CONSTANT");
    is(BAZ,   2, "BAZ CONSTANT");
    is(APPLE, 3, "APPLE CONSTANT");
    is(PEAR,  4, "PEAR CONSTANT");

    my $bad = eval { Test::Stream::ArrayBase->import( base => 'foobarbaz' ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/My::ABaseSub is already a subclass of 'My::ABase'/, "Expected error");
}

{
    package My::ABase;
    my $bad = eval { Test::Stream::ArrayBase->import( accessors => [qw/xerxes/] ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/Cannot add accessor, metadata is locked due to a subclass being initialized/, "Expected error");
}

{
    package Consumer;
    use My::ABase qw/BAR/;
    use Test::More;

    is(BAR, 1, "Can import contants");

    my $bad = eval { Test::Stream::ArrayBase->import( base => 'Test::More' ); 1 };
    my $error = $@;
    ok(!$bad, "Threw exception");
    like($error, qr/Base class 'Test::More' is not a subclass of Test::Stream::ArrayBase/, "Expected error");
}

isa_ok('My::ABase', 'Test::Stream::ArrayBase');
isa_ok('My::ABaseSub', 'Test::Stream::ArrayBase');
isa_ok('My::ABaseSub', 'My::ABase');

my $one = My::ABase->new(qw/a b c/);
is($one->foo, 'a', "Accessor");
is($one->bar, 'b', "Accessor");
is($one->baz, 'c', "Accessor");
$one->set_foo('x');
is($one->foo, 'x', "Accessor set");
$one->set_foo(undef);

is_deeply(
    $one->to_hash,
    {
        foo => undef,
        bar => 'b',
        baz => 'c',
    },
    'to_hash'
);

my $two = My::ABase->new_from_pairs(
    foo => 'foo',
    bar => 'bar',
);

is($two->foo, 'foo', "set by pair");
is($two->bar, 'bar', "set by pair");

done_testing;
