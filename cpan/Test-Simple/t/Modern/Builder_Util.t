use strict;
use warnings;

use Test::More 'modern';

{
    package My::Example;
    use Test::Builder::Util qw/
        import export exports accessor accessors delta deltas export_to transform
        atomic_delta atomic_deltas new
    /;

    export foo => sub { 'foo' };
    export 'bar';
    exports qw/baz bat/;

    sub bar { 'bar' }
    sub baz { 'baz' }
    sub bat { 'bat' }

    accessor apple => sub { 'fruit' };

    accessors qw/x y z/;

    delta number => 5;
    deltas qw/alpha omega/;

    transform add5 => sub { $_[1] + 5 };
    transform add6 => '_add6';

    sub _add6 { $_[1] + 6 }

    atomic_delta a_number => 5;
    atomic_deltas qw/a_alpha a_omega/;

    package My::Consumer;
    My::Example->import(qw/foo bar baz bat/);
}

can_ok(
    'My::Example',
    qw/
        import export accessor accessors delta deltas export_to transform
        atomic_delta atomic_deltas new

        bar baz bat
        apple
        x y z
        number
        alpha omega
        add5 add6
        a_number
        a_alpha a_omega
    /
);

can_ok('My::Consumer', qw/foo bar baz bat/);

use Test::Builder::Util qw/try protect package_sub is_tester is_provider find_builder/;

is(My::Consumer->$_, $_, "Simple sub $_") for qw/foo bar baz bat/;

my $one = My::Example->new(x => 1, y => 2, z => 3);
isa_ok($one, 'My::Example');
is($one->x, 1, "set at construction");
is($one->y, 2, "set at construction");
is($one->z, 3, "set at construction");

is($one->x(5), 5, "set value");
is($one->x(), 5, "kept value");

is($one->number, 5, "default");
is($one->number(2), 7, "Delta add the number");
is($one->number(-2), 5, "Delta add the number");

is($one->alpha, 0, "default");
is($one->alpha(2), 2, "Delta add the number");
is($one->alpha(-2), 0, "Delta add the number");

is($one->add5(3), 8, "transformed");
is($one->add6(3), 9, "transformed");

# XXX TODO: Test these in a threaded environment
is($one->a_number, 5, "default");
is($one->a_number(2), 7, "Delta add the number");
is($one->a_number(-2), 5, "Delta add the number");

is($one->a_alpha, 0, "default");
is($one->a_alpha(2), 2, "Delta add the number");
is($one->a_alpha(-2), 0, "Delta add the number");

can_ok( __PACKAGE__, 'try' );

{
    local $@ = "Blah";
    local $! = 23;
    my ($ok, $error) = try { $! = 22; die "XXX"; 1 };
    ok(!$ok, "Exception in the try");
    ok($! == 23, '$! is preserved');
    is($@, "Blah", '$@ is preserved');
    like($error, qr/XXX/, "Got exception");
}

{
    local $@ = "Blah";
    local $! = 23;
    my ($ok, $error) = try { $! = 22; $@ = 'XXX'; 1 };
    ok($ok, "No exception in the try");
    ok($! == 23, '$! is preserved');
    is($@, "Blah", '$@ is preserved');
}

{
    local $@ = "Blah";
    local $! = 23;
    my $ok;
    eval { $ok = protect { $! = 22; die "XXX"; 1 } };
    like($@, qr/XXX/, 'Threw exception');
    ok(!$ok, "Exception in the try");
    ok($! == 23, '$! is preserved');
}

{
    local $@ = "Blah";
    local $! = 23;
    my $ok = protect { $! = 22; $@ = 'XXX'; 1 };
    ok($ok, "Success");
    ok($! == 23, '$! is preserved');
    is($@, "Blah", '$@ is preserved');
}

{
    package TestParent;
    sub a { 'a' }

    package TestChildA;
    our @ISA = ( 'TestParent' );

    package TestChildB;
    our @ISA = ( 'TestParent' );
    sub a { 'A' }
}

is(package_sub(TestParent => 'a'), TestParent->can('a'), "Found sub in package");
is(package_sub(TestChildA => 'a'), undef, "No sub in child package (Did not inherit)");
is(package_sub(TestChildB => 'a'), TestChildB->can('a'), "Found sub in package");

ok(is_tester(__PACKAGE__), "We are a tester!");
ok(!is_provider(__PACKAGE__), "We are not a provider!");

ok(!is_tester('TestParent'), "not a tester!");
ok(!is_provider('TestParent'), "not a provider!");

ok(!is_tester('Test::More'), "not a tester!");
ok(is_provider('Test::More'), "a provider!");

isa_ok(find_builder(), 'Test::Builder');

done_testing;
