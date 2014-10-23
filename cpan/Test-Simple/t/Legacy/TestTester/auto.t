use strict;
use warnings;

BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use Test::Tester tests => 4;

use SmallTest;

use MyTest;

{
    my ($prem, @results) = run_tests(sub { MyTest::ok(1, "run pass") });

    is_eq($results[0]->{name}, "run pass");
    is_num($results[0]->{ok}, 1);
}

{
    my ($prem, @results) = run_tests(sub { MyTest::ok(0, "run fail") });

    is_eq($results[0]->{name}, "run fail");
    is_num($results[0]->{ok}, 0);
}
