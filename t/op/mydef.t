#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
}

plan tests => 1;

use strict;

eval 'my $_';
like $@, qr/^Can't use global \$_ in "my" at /;

