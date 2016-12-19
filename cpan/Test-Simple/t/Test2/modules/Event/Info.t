use strict;
use warnings;

use Test2::Tools::Tiny;

use Test2::Event::Info;
use Test2::Util::Trace;
use Test2::API qw/intercept/;

my @got;

my $info = Test2::Event::Info->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    renderer => sub { @got = @_; 'foo' },
);

is($info->summary, 'foo', "summary is just rendering");
is_deeply(\@got, ['text'], "got text");

is($info->summary('blah'), 'foo', "summary is just rendering (arg)");
is_deeply(\@got, ['blah'], "got arg");

{
    package An::Info::Thingy;
    sub render { shift; @got = @_; 'foo' }
}

$info = Test2::Event::Info->new(
    trace => Test2::Util::Trace->new(frame => [__PACKAGE__, __FILE__, __LINE__]),
    renderer => bless({}, 'An::Info::Thingy'),
);

is($info->summary, 'foo', "summary is just rendering");
is_deeply(\@got, ['text'], "got text");

is($info->summary('blah'), 'foo', "summary is just rendering (arg)");
is_deeply(\@got, ['blah'], "got arg");

eval { Test2::Event::Info->new(trace => Test2::Util::Trace->new(frame => ['Foo', 'foo.pl', 42])) };
like(
    $@,
    qr/'renderer' is a required attribute at foo\.pl line 42/,
    "Got expected error"
);

# For #727
$info = intercept { ok(0, 'xxx', sub { 'xxx-yyy' }); }->[-1];
ok($info->isa('Test2::Event::Info'), "Got an Info event");
is($info->render, 'xxx-yyy', "Got rendered info");

done_testing;
