#!perl -w
use strict;

require './test.pl';

plan (tests => 8);
no warnings 'deprecated';

# Bug #27024
{
    # this used to segfault (because $[=1 is optimized away to a null block)
    my $x;
    $[ = 1 while $x;
    pass('#27204');
    $[ = 0; # restore the original value for less side-effects
}

# [perl #36313] perl -e "1for$[=0" crash
{
    my $x;
    $x = 1 for ($[) = 0;
    pass('optimized assignment to $[ used to segfault in list context');
    if ($[ = 0) { $x = 1 }
    pass('optimized assignment to $[ used to segfault in scalar context');
    $x = ($[=2.4);
    is($x, 2, 'scalar assignment to $[ behaves like other variables');
    $x = (($[) = 0);
    is($x, 1, 'list assignment to $[ behaves like other variables');
    $x = eval q{ ($[, $x) = (0) };
    like($@, qr/That use of \$\[ is unsupported/,
             'cannot assign to $[ in a list');
    eval q{ ($[) = (0, 1) };
    like($@, qr/That use of \$\[ is unsupported/,
             'cannot assign list of >1 elements to $[');
    eval q{ ($[) = () };
    like($@, qr/That use of \$\[ is unsupported/,
             'cannot assign list of <1 elements to $[');
}
