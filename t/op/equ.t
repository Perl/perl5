#!./perl

use strict;
use warnings;

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

### PPC0030-style `equ` operator

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

### PPC0031-style `eq:u` flag on operator

# eq:u behaves like eq on defined strings
ok("abc" eq:u "abc",      'eq:u on identical values');
ok("" eq:u "",            'eq:u on empty/empty');
ok(not("abc" eq:u "def"), 'eq:u on different values');

# eq:u treats undef as distinct, equal to itself, with no warnings
{
    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++; };

    ok(undef eq:u undef,   'eq:u on undef/undef');
    ok(not(undef eq:u ""), 'eq:u on undef/empty');

    is($warnings, 0, 'no warnings were produced by use of undef');
}

# performs GETMAGIC
{
    "abc" =~ m/(\d+)/;
    # $1 should now be undef
    "abc" =~ m/(\w+)/;
    ok($1 eq:u "abc", 'eq:u performs GETMAGIC');
}

done_testing();
