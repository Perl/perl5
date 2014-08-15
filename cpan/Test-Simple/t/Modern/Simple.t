use strict;
use warnings;

use Test::Simple tests => 4, 'modern';
use Test::Tester2;

ok(Test::Simple->can('TB_PROVIDER_META'), "Test::Simple is a provider");

my $results = intercept {
    ok( 1, "A pass" );
    ok( 0, "A fail" );
};

ok(@$results == 3, "found 3 results (2 oks, and 1 diag)");

ok($results->[0]->trace->report->line == 10, "Reported correct line result 1");
ok($results->[2]->trace->report->line == 11, "Reported correct line result 2");
