use strict;
use warnings;

use Test::More 'modern';

require_ok 'Test::Builder::Event::Finish';

my $one = Test::Builder::Event::Finish->new();

isa_ok($one, 'Test::Builder::Event::Finish');
isa_ok($one, 'Test::Builder::Event');

can_ok($one, qw/tests_run tests_failed/);

done_testing;
