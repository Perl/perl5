use strict;
use warnings;
use Test::More;
use Test::Tester2;
use Test::Builder::Event::Ok;
use Config;

my $Can_Fork = $Config{d_fork} ||
               (($^O eq 'MSWin32' || $^O eq 'NetWare') and
                $Config{useithreads} and
                $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/
               );

if( !$Can_Fork ) {
    plan 'skip_all' => "This system cannot fork";
}

my $CLASS = 'Test::Builder::Fork';
require_ok $CLASS;

my $one = $CLASS->new;
isa_ok($one, $CLASS);
ok($one->tmpdir, "Got temp dir");

my $TB = Test::Builder->new;

my $Ok = Test::Builder::Event::Ok->new(
    bool      => 1,
    real_bool => 1,
    name      => 'fake',
);

my $out = $one->handle($Ok);
ok(!$out, "Did not snatch event in parent process");

if (my $pid = fork()) {
    waitpid($pid, 0);
}
else {
    $one->handle($Ok);
    exit 0;
}

my $events = intercept { $one->cull() };

is_deeply(
    $events,
    [$Ok],
    "got event after cull"
);

done_testing;
