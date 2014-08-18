#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'modern';

my $CLASS = 'Test::Builder::Trace::Frame';
require_ok $CLASS;

my @BUILDERS = (
    'Test::Builder::Trace',
    'Test::Builder',
    'Test::Builder::Event',
    'Test::Builder::Event::Bail',
    'Test::Builder::Event::Child',
    'Test::Builder::Event::Diag',
    'Test::Builder::Event::Note',
    'Test::Builder::Event::Ok',
    'Test::Builder::Event::Plan',
    'Test::Builder::Stream',
    'Test::Builder::Trace',
    'Test::Builder::Util',
);

for my $pkg (@BUILDERS) {
    my $frame = $CLASS->new(2, $pkg, __FILE__, 1, 'foo');
    ok($frame->builder, "Detected builder ($pkg)");
}

my $one = $CLASS->new(2, __PACKAGE__, __FILE__, 42, 'Foo::Bar::baz');
is($one->depth, 2, "Got depth");
is($one->package, __PACKAGE__, "got package");
is($one->file, __FILE__, "Got file");
is($one->line, 42, "Got line");
is($one->subname, 'Foo::Bar::baz', "got subname");

is($one->level, undef, "Level boolean not set");
is($one->report, undef, "Report boolean not set");
is($one->level(1), 1, "Level boolean set");
is($one->report(1), 1, "Report boolean set");

is_deeply(
    [ $one->call ],
    [ __PACKAGE__, __FILE__, 42, 'Foo::Bar::baz' ],
    "Got call"
);

ok(!$one->transition, "Not a transition");
ok(!$one->nest, "Not a nest");
ok($one->anointed, "Is annointed");
is($one->provider_tool, undef, "not a provider tool");

my $two = $CLASS->new(2, 'Fake::McKaferson', 'Fake.t', 42, 'Test::Builder::Trace::nest');
ok($two->transition, "This is a transition");
ok($two->nest, "This is a nest");
ok(!$two->anointed, "Not anointed");
is($two->provider_tool, undef, "not a provider tool");

my $three = $CLASS->new(2, 'Fake::McKaferson', 'Fake.t', 42, 'Test::More::is');
ok(!$three->transition, "This is not a transition");
ok(!$three->nest, "This is not a nest");
ok(!$three->anointed, "Not anointed");
is_deeply(
    $three->provider_tool,
    Test::More->TB_PROVIDER_META->{attrs}->{'is'},
    "provider tool"
);

{
    package My::Provider;
    use Test::Builder::Provider;

    provide foo => sub { return caller(1) };
}

My::Provider->import;

my @call = foo();
my $anon_name = $call[3];

my $four = $CLASS->new(2, 'Fake::McKaferson', 'Fake.t', 42, $anon_name);
is_deeply(
    $four->provider_tool,
    My::Provider->TB_PROVIDER_META->{attrs}->{'foo'},
    "provider tool (anon)"
);

done_testing;
