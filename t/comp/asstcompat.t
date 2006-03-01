#!./perl

BEGIN { $^W = 0 }

my $i = 1;
sub ok {
    my $ok = shift;
    print( ($ok ? '' : 'not '), "ok $i", (@_ ? " - @_" : ''), "\n");
    $i++;
}

print "1..7\n";

# 1
use base 'assertions::compat';
ok(eval "sub assert_foo : assertion { 0 } ; 1", "handle assertion attribute");

use assertions::activate 'Foo';

# 2
use assertions::compat asserting_2 => 'Foo';
ok(asserting_2, 'on');

# 3
use assertions::compat asserting_3 => 'Bar';
ok(!asserting_3, 'off');

# 4
use assertions::compat asserting_4 => '_ || Bar';
ok(!asserting_4, 'current off or off');

# 5
use assertions::compat asserting_5 => '_ || Foo';
ok(asserting_5, 'current off or on');

# 6
use assertions::compat asserting_6 => '_ || Bar';
ok(asserting_6, 'current on or off');

# 7
use assertions::compat asserting_7 => '_ && Foo';
ok(asserting_7, 'current on and on');
