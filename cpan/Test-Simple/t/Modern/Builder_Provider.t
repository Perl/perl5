use strict;
use warnings;

use Scalar::Util qw/reftype/;

{
    package My::Provider;
    use Test::Builder::Provider;
}

My::Provider->import();
my $anointed = __PACKAGE__->can('TB_TESTER_META');

require Test::More;
Test::More->import;

ok($anointed, "Importing our provider anointed us");

can_ok(
    'My::Provider',
    qw{
        TB_PROVIDER_META builder TB anoint gives give provides provide export
        import nest
    }
);

is(reftype(My::Provider->TB_PROVIDER_META), 'HASH', "Got Metadata");

isa_ok(My::Provider->builder, 'Test::Builder');
isa_ok(My::Provider->TB,      'Test::Builder');

{
    package My::Provider;

    provide foo => sub { 'foo' };
    provide hsh => { a => 1 };

    give xxx => sub { 'xxx' };
    give arr => [ 1 .. 5 ];

    provide nestx => sub(&) { TB->ok(&nest($_[0]), "Internal") };

    provides qw/bar baz/;
    gives    qw/aaa bbb/;

    provides qw/nesta nestb/;

    sub bar { 'bar' }
    sub baz { 'baz' }
    sub aaa { 'aaa' }
    sub bbb { 'bbb' }

    sub nesta { &nest($_->[0]) }
    sub nestb { &nest($_->[0]) }
}

My::Provider->import();

can_ok(
    __PACKAGE__,
    qw{ foo xxx nestx bar baz aaa bbb nesta nestb }
);

{
    no strict 'vars';
    no warnings 'once';
    is_deeply(\%hsh, { a => 1 }, "imported hash");
    is_deeply(\@arr, [ 1 .. 5 ], "imported array");
}

nestx(
    sub { ok(1, "Foo") }
);

done_testing();
