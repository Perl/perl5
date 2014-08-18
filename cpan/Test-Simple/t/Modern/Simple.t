use strict;
use warnings;

use Test::Simple tests => 4, 'modern';
use Test::Tester2;

ok(Test::Simple->can('TB_PROVIDER_META'), "Test::Simple is a provider");

my $events = intercept {
    ok( 1, "A pass" );
    ok( 0, "A fail" );
};

ok(@$events == 3, "found 3 events (2 oks, and 1 diag)");

ok($events->[0]->trace->report->line == 10, "Reported correct line event 1");
ok($events->[2]->trace->report->line == 11, "Reported correct line event 2");

