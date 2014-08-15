use strict;
use warnings;
use Test::More;
use Test::Tester2;
use Test::Builder::Result::Ok;

my $CLASS = 'Test::Builder::Fork';
require_ok $CLASS;

my $one = $CLASS->new;
isa_ok($one, $CLASS);
ok($one->tmpdir, "Got temp dir");

my $TB = Test::Builder->new;

my $Ok = Test::Builder::Result::Ok->new(
    bool      => 1,
    real_bool => 1,
    name      => 'fake',
);

my $out = $one->handle($Ok);
ok(!$out, "Did not snatch result in parent process");

if (my $pid = fork()) {
    waitpid($pid, 0);
}
else {
    $one->handle($Ok);
    exit 0;
}

my $results = intercept { $one->cull() };

is_deeply(
    $results,
    [$Ok],
    "got result after cull"
);

done_testing;
