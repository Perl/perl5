#!perl -w
use strict;
no warnings 'deprecated';

BEGIN {
 require './test.pl';
 skip_all_if_miniperl();
}

plan (tests => 4);

is(eval('$['), 0);
is(eval('$[ = 0; 123'), 123);
is(eval('$[ = 1; 123'), 123);
ok $INC{'arybase.pm'};

1;
