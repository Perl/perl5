use strict;
use warnings;

use Test::More 'modern';
use Test::Tester2;

can_ok( __PACKAGE__, 'intercept', 'results_are' );

my $results = intercept {
    ok(1, "Woo!");
    ok(0, "Boo!");
};

isa_ok($results->[0], 'Test::Builder::Result::Ok');
is($results->[0]->bool, 1, "Got one success");
is($results->[0]->name, "Woo!", "Got test name");

isa_ok($results->[1], 'Test::Builder::Result::Ok');
is($results->[1]->bool, 0, "Got one fail");
is($results->[1]->name, "Boo!", "Got test name");

$results = intercept {
    ok(1, "Woo!");
    BAIL_OUT("Ooops");
    ok(0, "Should not see this");
};
is(@$results, 2, "Only got 2");
isa_ok($results->[0], 'Test::Builder::Result::Ok');
isa_ok($results->[1], 'Test::Builder::Result::Bail');

$results = intercept {
    plan skip_all => 'All tests are skipped';

    ok(1, "Woo!");
    BAIL_OUT("Ooops");
    ok(0, "Should not see this");
};
is(@$results, 1, "Only got 1");
isa_ok($results->[0], 'Test::Builder::Result::Plan');

results_are(
    intercept {
        results_are(
            intercept { ok(1, "foo") },
            ok => {id => 'blah', bool => 0},
            end => 'Lets name this test!',
        );
    },

    ok => {id => 'first', bool => 0},

    diag => {message => qr{Failed test 'Lets name this test!'.*at (\./)?t/Modern/Tester2\.t line}s},
    diag => {message => q{(ok blah) Wanted bool => '0', but got bool => '1'}},
    diag => {message => <<"    EOT"},
Full result found was: ok => {
  name: foo
  bool: 1
  real_bool: 1
  in_todo: 0
  package: main
  file: t/Modern/Tester2.t
  line: 44
  pid: $$
  depth: 0
  source: t/Modern/Tester2.t
  tool_name: ok
  tool_package: Test::More
  tap: ok - foo
}
    EOT
    end => 'Failure diag checking',
);

results_are(
    intercept {
        results_are(
            intercept { ok(1, "foo"); ok(1, "bar") },
            ok => {id => 'blah', bool => 1},
            'end'
        );
    },

    ok => {id => 'first', bool => 0},

    diag => {},
    diag => {message => q{Expected end of results, but more results remain}},

    end => 'skipping a diag',
);

{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn => @_ };
    my $doit = sub {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        ok(1, "example");
    };

    # The results generated here are to be ignored. We are just checking on warnings.
    intercept { $doit->(); $doit->(); $doit->() };

    is(@warn, 1, "got a warning, but only once");
    like($warn[0], qr/\$Test::Builder::Level was used to trace a test! \$Test::Builder::Level is deprecated!/, "Expected warning");
}

DOCS_1: {
    # Intercept all the Test::Builder::Result objects produced in the block.
    my $results = intercept {
        ok(1, "pass");
        ok(0, "fail");
        diag("xxx");
    };

    # By Hand
    is($results->[0]->{bool}, 1, "First result passed");

    # With help
    results_are(
        $results,
        ok   => { id => 'a', bool => 1, name => 'pass' },
        ok   => { id => 'b', bool => 0, name => 'fail' },
        diag => { message => qr/Failed test 'fail'/ },
        diag => { message => qr/xxx/ },
        end => 'docs 1',
    );
}

DOCS_2: {
    require Test::Simple;
    my $results = intercept {
        Test::More::ok(1, "foo");
        Test::More::ok(1, "bar");
        Test::More::ok(1, "baz");
        Test::Simple::ok(1, "bat");
    };

    results_are(
        $results,
        ok => { name => "foo" },
        ok => { name => "bar" },

        # From this point on, only more 'Test::Simple' results will be checked.
        filter_provider => 'Test::Simple',

        # So it goes right to the Test::Simple result.
        ok => { name => "bat" },

        end => 'docs 2',
    );
}

DOCS_3: {
    my $results = intercept {
        ok(1, "foo");
        diag("XXX");

        ok(1, "bar");
        diag("YYY");

        ok(1, "baz");
        diag("ZZZ");
    };

    results_are(
        $results,
        ok => { name => "foo" },
        diag => { message => 'XXX' },
        ok => { name => "bar" },
        diag => { message => 'YYY' },

        # From this point on, only 'diag' types will be seen
        filter_type => 'diag',

        # So it goes right to the next diag.
        diag => { message => 'ZZZ' },

        end => 'docs 3',
    );
}

DOCS_4: {
    my $results = intercept {
        ok(1, "foo");
        diag("XXX");

        ok(1, "bar");
        diag("YYY");

        ok(1, "baz");
        diag("ZZZ");
    };

    results_are(
        $results,
        ok => { name => "foo" },

        skip => 1, # Skips the diag

        ok => { name => "bar" },

        skip => 2, # Skips a diag and an ok

        diag => { message => 'ZZZ' },

        end => 'docs 4'
    );
}

DOCS_5: {
    my $results = intercept {
        ok(1, "foo");

        diag("XXX");
        diag("YYY");
        diag("ZZZ");

        ok(1, "bar");
    };

    results_are(
        $results,
        ok => { name => "foo" },

        skip => '*', # Skip until the next 'ok' is found since that is our next check.

        ok => { name => "bar" },

        end => 'docs 5',
    );
}

DOCS_6: {
    my $results = intercept {
        ok(1, "foo");

        diag("XXX");
        diag("YYY");

        ok(1, "bar");
        diag("ZZZ");

        ok(1, "baz");
    };

    results_are(
        intercept {
            results_are(
                $results,

                name => 'docs 6 inner',

                seek => 1,
                ok => { name => "foo" },
                # The diags are ignored,
                ok => { name => "bar" },

                seek => 0,

                # This will fail because the diag is not ignored anymore.
                ok => { name => "baz" },
            );
        },

        ok => { bool => 0 },
        diag => { message => qr/Failed test 'docs 6 inner'/ },
        diag => { message => q{(ok 3) Wanted result type 'ok', But got: 'diag'} },
        diag => { message => qr/Full result found was:/ },

        end => 'docs 6',
    );
}

done_testing;
