use strict;
use Test::More;
use ok;
use ok 'strict';
use ok 'Test::More';
use ok 'ok';

my $class = 'Test::Builder';
BEGIN {
    ok(!$class, '$class is declared, but not yet set');


    my $success = eval 'use ok $class';
    my $error = $@;

    ok(!$success, "Threw an exception");
    like(
        $error,
        qr/^'use ok' called with an empty argument, did you try to use a package name from an uninitialized variable\?/,
        "Threw expected exception"
    );



    $success = eval 'use ok $class, "xxx"';
    $error = $@;

    ok(!$success, "Threw an exception");
    like(
        $error,
        qr/^'use ok' called with an empty argument, did you try to use a package name from an uninitialized variable\?/,
        "Threw expected exception when arguments are added"
    );
}

my $class2;
BEGIN {$class2 = 'Test::Builder'};
use ok $class2;

done_testing;
