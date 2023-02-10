#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.36;
use feature 'class';
no warnings 'experimental::class';

{
    class Test1A {
        field $x;
        ADJUST { $x = "base class" }
        method x { return $x; }
    }

    class Test1B :isa(Test1A) {
        field $y;
        ADJUST { $y = "derived class" }
        method y { return $y; }
    }

    my $obj = Test1B->new;
    ok($obj isa Test1B, 'Object is its own class');
    ok($obj isa Test1A, 'Object is also its base class');

    ok(eq_array(\@Test1B::ISA, ["Test1A"]), '@Test1B::ISA is set correctly');

    is($obj->y, "derived class", 'Object has derived class field');

    can_ok($obj, "x");
    is($obj->x, "base class", 'Object has base class field');

    class Test1C :isa(    Test1A    ) { }

    my $objc = Test1C->new;
    ok($objc isa Test1A, ':isa attribute trims whitespace');
}

{
    class Test2A 1.23 { }

    class Test2B :isa(Test2A 1.0) { } # OK

    ok(!defined eval "class Test2C :isa(Test2A 2.0) {}; 1",
        ':isa() version test can throw');
    like($@, qr/^Test2A version 2\.0 required--this is only version 1\.23 at /,
        'Exception thrown from :isa version test');
}

done_testing;
