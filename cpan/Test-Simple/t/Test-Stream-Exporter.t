use strict;
use warnings;

use Test::More;

{
    package My::Exporter;
    use Test::Stream::Exporter;
    use Test::More;

    export         a => sub { 'a' };
    default_export b => sub { 'b' };

    export 'c';
    sub c { 'c' }

    default_export x => sub { 'x' };

    our $export = "here";
    $main::export::xxx = 'here';

    export '$export' => \$export;

    Test::Stream::Exporter->cleanup;

    is($export,            'here', "still have an \$export var");
    is($main::export::xxx, 'here', "still have an \$export::* var");

    ok(!__PACKAGE__->can($_), "removed $_\()") for qw/export default_export exports default_exports/;

    my $ok = eval {
        export no => sub { 'no' };
        1;
    };
    my $error = $@;
    ok(!$ok, "Cannot add exports after cleanup");
    like($error, qr/Undefined subroutine &My::Exporter::export called/, "Sub was removed");
}

My::Exporter->import( '!x' );

can_ok(__PACKAGE__, qw/b/);
ok(!__PACKAGE__->can($_), "did not import $_\()") for qw/a c x/;

My::Exporter->import(qw/a c/);
can_ok(__PACKAGE__, qw/a b c/);

ok(!__PACKAGE__->can($_), "did not import $_\()") for qw/x/;

My::Exporter->import();
can_ok(__PACKAGE__, qw/a b c x/);

is(__PACKAGE__->$_(), $_, "$_() eq '$_', Function is as expected") for qw/a b c x/;

ok(! defined $::export, "no export scalar");
My::Exporter->import('$export');
is($::export, 'here', "imported export scalar");

use Test::Stream::Exporter qw/export_meta/;
my $meta = export_meta('My::Exporter');
isa_ok($meta, 'Test::Stream::Exporter::Meta');
is_deeply(
    [sort $meta->default],
    [sort qw/b x/],
    "Got default list"
);

is_deeply(
    [sort $meta->all],
    [sort qw/a b c x $export/],
    "Got all list"
);

is_deeply(
    $meta->exports,
    {
        a => __PACKAGE__->can('a') || undef,
        b => __PACKAGE__->can('b') || undef,
        c => __PACKAGE__->can('c') || undef,
        x => __PACKAGE__->can('x') || undef,

        '$export' => \$My::Exporter::export,
    },
    "Exports are what we expect"
);

done_testing;
