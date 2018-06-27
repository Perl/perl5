use strict;
use warnings;

use Test2::Tools::Tiny;

use Test2::API qw/run_subtest intercept/;

my $events = intercept {
	todo 'testing todo', sub {
		run_subtest(
			'fails in todo',
			sub {
				ok(1, 'first passes');
				ok(0, 'second fails');
			});
	};
};

ok($events->[1],                 'Test2::Event::Subtest', 'subtest ran');
ok($events->[1]->effective_pass, 'Test2::Event::Subtest', 'subtest effective_pass is true');
ok($events->[1]->todo,           'testing todo',          'subtest todo is set to expected value');
my @oks = grep { $_->isa('Test2::Event::Ok') } @{$events->[1]->subevents};
is(scalar @oks, 2, 'got 2 Ok events in the subtest');
ok($oks[0]->pass,           'first event passed');
ok($oks[0]->effective_pass, 'first event effective_pass is true');
ok(!$oks[1]->pass,          'second event failed');
ok($oks[1]->effective_pass, 'second event effective_pass is true');

done_testing;
