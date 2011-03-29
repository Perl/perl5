#!perl -w
use strict;

use Test::More tests => 1;
use XS::APItest;

BEGIN { eval "BEGIN{ filter() }" }

is "foo", "fee", "evals share filters with the currently compiling scope";
# See [perl #87064].
