BEGIN {
    require Test::Harness;
    require Test::More;

    if( $Test::Harness::VERSION < 1.23 ) {
        Test::More->import(skip_all => 'Need the new Test::Harness');
    }
    else {
        Test::More->import(tests => 13);
    }
}

$Why = 'Just testing the todo interface.';

TODO: {
    local $TODO = $Why;

    fail("Expected failure");
    fail("Another expected failure");
}


pass("This is not todo");


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
