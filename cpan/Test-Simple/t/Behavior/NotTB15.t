#!/usr/bin/perl
use strict;
use warnings;

use Test::More;
use Test::Builder;

# This is just a list of method Test::Builder current does not have that Test::Builder 1.5 does.
my @TB15_METHODS = qw{
    _file_and_line _join_message _make_default _my_exit _reset_todo_state
    _result_to_hash _results _todo_state formatter history in_test
    no_change_exit_code post_event post_result set_formatter set_plan test_end
    test_exit_code test_start test_state
};

for my $method (qw/foo bar baz/) {
    my $success = !eval { Test::Builder->$method; 1 }; my $line = __LINE__;
    my $error = $@;
    ok($success, "Threw an exception ($method)");
    is(
        $error,
        qq{Can't locate object method "$method" via package "Test::Builder" at } . __FILE__ . " line $line.\n",
        "Did not auto-create random sub ($method)"
    );
}

my $file = __FILE__;
for my $method (@TB15_METHODS) {
    my $success = !eval { Test::Builder->$method; 1 }; my $line = __LINE__;
    my $error = $@;

    ok($success, "Threw an exception ($method)");

    is($error, <<"    EOT", "Got expected error ($method)");
Can't locate object method "$method" via package "Test::Builder" at $file line $line.

    *************************************************************************
    '$method' is a Test::Builder 1.5 method. Test::Builder 1.5 is a dead branch.
    You need to update your code so that it no longer treats Test::Builders
    over a specific version number as anything special.

    See: http://blogs.perl.org/users/chad_exodist_granum/2014/03/testmore---new-maintainer-also-stop-version-checking.html
    *************************************************************************
    EOT
}

done_testing;

