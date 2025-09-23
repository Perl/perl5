#!./perl

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

# equ behaves like eq on defined strings
ok("abc" equ "abc",      'equ on identical values');
ok("" equ "",            'equ on empty/empty');
ok(not("abc" equ "def"), 'equ on different values');

# equ treats undef as distinct, equal to itself, with no warnings
{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++; };

    ok(undef equ undef,   'equ on undef/undef');
    ok(not(undef equ ""), 'equ on undef/empty');

    is($warnings, 0, 'no warnings were produced by use of undef');
}

# performs GETMAGIC
{
    "abc" =~ m/(\d+)/;
    # $1 should now be undef
    "abc" =~ m/(\w+)/;
    ok($1 equ "abc", 'equ performs GETMAGIC');
}

done_testing();
