#!perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = '../lib';
    }
}

require Test::Harness;
use Test::More;

# This feature requires a fairly new version of Test::Harness
(my $th_version = $Test::Harness::VERSION) =~ s/_//; # for X.Y_Z alpha versions
if( $th_version < 2.03 ) {
    plan tests => 1;
    fail "Need Test::Harness 2.03 or up.  You have $th_version.";
    exit;
}

plan tests => 16;


$Why = 'Just testing the todo interface.';

my $is_todo;
TODO: {
    local $TODO = $Why;

    fail("Expected failure");
    fail("Another expected failure");

    $is_todo = Test::More->builder->todo;
}

pass("This is not todo");
ok( $is_todo, 'TB->todo' );


TODO: {
    local $TODO = $Why;

    fail("Yet another failure");
}

pass("This is still not todo");


TODO: {
    local $TODO = "testing that error messages don't leak out of todo";

    ok( 'this' eq 'that',   'ok' );

    like( 'this', '/that/', 'like' );
    is(   'this', 'that',   'is' );
    isnt( 'this', 'this',   'isnt' );

    can_ok('Fooble', 'yarble');
    isa_ok('Fooble', 'yarble');
    use_ok('Fooble');
    require_ok('Fooble');
}


TODO: {
    todo_skip "Just testing todo_skip", 2;

    fail("Just testing todo");
    die "todo_skip should prevent this";
    pass("Again");
}
