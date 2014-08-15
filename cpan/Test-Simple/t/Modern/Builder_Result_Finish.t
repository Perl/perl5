use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Result::Finish';

my $one = Test::Builder::Result::Finish->new();

isa_ok($one, 'Test::Builder::Result::Finish');
isa_ok($one, 'Test::Builder::Result');

can_ok($one, qw/tests_run tests_failed/);

done_testing;
