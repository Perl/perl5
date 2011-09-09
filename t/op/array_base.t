#!perl -w
use strict;

require './test.pl';

plan (tests => 4);

is(eval('$['), 0);
is(eval('$[ = 0; 123'), 123);
is(eval('$[ = 1; 123'), undef);
like($@, qr/\AAssigning non-zero to \$\[ is no longer possible/);

1;
