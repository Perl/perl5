use strict;
use warnings;

use Test2::V0 -target => 'Test2::Compare::Base';

use Test2::Compare qw/build/;

subtest verify_build_default => sub {
    my $one = $CLASS->new();

    ok(lives { $one->verify_build }, "the base class accepts any build");
    is($one->verify_build, undef, "the default returns nothing");
};

subtest throw_build_error => sub {
    my $one = $CLASS->new(file => 'foo.t', lines => [42, 44]);

    is(
        dies { $one->throw_build_error("oops") },
        "oops at foo.t line 42.\n",
        "reports the message against the first line of the check"
    );

    my $bare = $CLASS->new();
    is(
        dies { $bare->throw_build_error("oops") },
        "oops at unknown file line 0.\n",
        "reports a placeholder when the check has no file or lines"
    );
};

subtest build_always_calls_verify_build => sub {
    my $file = __FILE__;

    my $check = build('Test2::Compare::Base', sub { });
    ok($check->isa($CLASS), "a class that does not override verify_build still builds");

    no warnings 'redefine';
    local *Test2::Compare::Base::verify_build = sub { $_[0]->throw_build_error("nope") };

    like(
        dies { my $bad = build('Test2::Compare::Base', sub { }) },
        qr/^nope at \Q$file\E line \d+\.\n$/,
        "build calls verify_build on the built check"
    );
};

done_testing;
