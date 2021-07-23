#!perl

# see if using Math::BigInt and Math::BigFloat works together nicely.
# all use_lib*.t should be equivalent

use strict;
use warnings;
use lib 't';

use Test::More tests => 1;

use Math::BigInt lib => 'BareCalc';
eval "use Math::BigFloat only => 'foobar';";

my $regex = "Couldn't load the specified math lib"
          . ".*and fallback.*is disallowed";
like($@, qr/$regex/);
