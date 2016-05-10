use strict;
use warnings;
BEGIN { require "t/tools.pl" };
BEGIN {
    $INC{'My/HBase.pm'} = __FILE__;

    package My::HBase;
    use Test2::Util::HashBase qw/foo bar baz/;

    main::is(FOO, 'foo', "FOO CONSTANT");
    main::is(BAR, 'bar', "BAR CONSTANT");
    main::is(BAZ, 'baz', "BAZ CONSTANT");
}

BEGIN {
    package My::HBaseSub;
    use base 'My::HBase';
    use Test2::Util::HashBase qw/apple pear/;

    main::is(FOO,   'foo',   "FOO CONSTANT");
    main::is(BAR,   'bar',   "BAR CONSTANT");
    main::is(BAZ,   'baz',   "BAZ CONSTANT");
    main::is(APPLE, 'apple', "APPLE CONSTANT");
    main::is(PEAR,  'pear',  "PEAR CONSTANT");
}

my $one = My::HBase->new(foo => 'a', bar => 'b', baz => 'c');
is($one->foo, 'a', "Accessor");
is($one->bar, 'b', "Accessor");
is($one->baz, 'c', "Accessor");
$one->set_foo('x');
is($one->foo, 'x', "Accessor set");
$one->set_foo(undef);

is_deeply(
    $one,
    {
        foo => undef,
        bar => 'b',
        baz => 'c',
    },
    'hash'
);

BEGIN {
    package My::Const::Test;
    use Test2::Util::HashBase qw/foo/;

    sub do_it {
        if (FOO()) {
            return 'const';
        }
        return 'not const'
    }
}

my $pkg = 'My::Const::Test';
is($pkg->do_it, 'const', "worked as expected");
{
    local $SIG{__WARN__} = sub { };
    *My::Const::Test::FOO = sub { 0 };
}
ok(!$pkg->FOO, "overrode const sub");
is($pkg->do_it, 'const', "worked as expected, const was constant");

BEGIN {
    $INC{'My/HBase/Wrapped.pm'} = __FILE__;

    package My::HBase::Wrapped;
    use Test2::Util::HashBase qw/foo bar/;

    my $foo = __PACKAGE__->can('foo');
    no warnings 'redefine';
    *foo = sub {
        my $self = shift;
        $self->set_bar(1);
        $self->$foo(@_);
    };
}

BEGIN {
    $INC{'My/HBase/Wrapped/Inherit.pm'} = __FILE__;

    package My::HBase::Wrapped::Inherit;
    use base 'My::HBase::Wrapped';
    use Test2::Util::HashBase;
}

my $o = My::HBase::Wrapped::Inherit->new(foo => 1);
my $foo = $o->foo;
is($o->bar, 1, 'parent attribute sub not overridden');

{
    package Foo;

    sub new;

    use Test2::Util::HashBase qw/foo bar baz/;

    sub new { 'foo' };
}

is(Foo->new, 'foo', "Did not override existing 'new' method");

done_testing;
