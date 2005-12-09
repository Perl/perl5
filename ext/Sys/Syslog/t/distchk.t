use strict;
use Test::More;
eval "use Test::Distribution not => [qw(versions podcover use)]";
plan skip_all => "Test::Distribution required for checking distribution" if $@;
