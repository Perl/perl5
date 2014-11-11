use strict;
use warnings;

use Test::Stream;
use Test::More;

use ok 'Test::Stream::Toolset';

can_ok(__PACKAGE__, qw/is_tester init_tester context/);

done_testing;
