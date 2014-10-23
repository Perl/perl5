use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'Test::Stream::Meta';

my $meta = init_tester('Some::Package');
ok($meta, "got meta");
isa_ok($meta, 'Test::Stream::Meta');
can_ok($meta, qw/package encoding modern todo stream/);

is(is_tester('Some::Package'), $meta, "remember the meta");

done_testing;
