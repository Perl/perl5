use Test::More tests => 9;

# If we skip with the same name, Test::Harness will report it back and
# we won't get lots of false bug reports.
my $Why = "Just testing the skip interface.";

SKIP: {
    skip $Why, 2 
      unless Pigs->can('fly');

    my $pig = Pigs->new;
    $pig->takeoff;

    ok( $pig->altitude > 0,         'Pig is airborne' );
    ok( $pig->airspeed > 0,         '  and moving'    );
}


SKIP: {
    skip "We're not skipping", 2 if 0;

    pass("Inside skip block");
    pass("Another inside");
}


SKIP: {
    skip "Again, not skipping", 2 if 0;

    my($pack, $file, $line) = caller;
    is( $pack || '', '',      'calling package not interfered with' );
    is( $file || '', '',      '  or file' );
    is( $line || '', '',      '  or line' );
}


SKIP: {
    skip $Why, 2 if 1;

    die "A horrible death";
    fail("Deliberate failure");
    fail("And again");
}
