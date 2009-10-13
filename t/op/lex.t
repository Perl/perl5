#!perl -w
use strict;

require './test.pl';

plan(tests => 2);

{
    no warnings 'deprecated';
    print <<;   # Yow!
ok 1

    # previous line intentionally left blank.

    my $yow = "ok 2";
    print <<;   # Yow!
$yow

    # previous line intentionally left blank.
}

curr_test(3);
