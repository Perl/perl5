BEGIN {
    require Test::Harness;
    require Test::More;

    if( $Test::Harness::VERSION < 1.23 ) {
        Test::More->import(skip_all => 'Need the new Test::Harness');
    }
    else {
        Test::More->import(tests => 5);
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
