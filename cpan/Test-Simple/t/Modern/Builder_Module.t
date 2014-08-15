use strict;
use warnings;

use Test::More 'modern';

my @warnings;
{
    local $SIG{__WARN__} = sub { push @warnings => @_ };
    require_ok 'Test::Builder::Module';
    Test::Builder::Module->import;
}

is($warnings[0], "Test::Builder::Module is deprecated!\n", "'Test::Builder::Module' is deprecated");

done_testing;
