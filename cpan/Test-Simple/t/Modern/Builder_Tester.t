use strict;
use warnings;

use Test::More 'modern';

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    require_ok 'Test::Builder::Tester';
    Test::Builder::Tester->import;
}

is($warnings[0], "Test::Builder::Tester is deprecated!\n", "'Test::Builder::Tester' is deprecated");

done_testing;
