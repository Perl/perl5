#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    require Config;
}

use v5.42;
use feature 'class';
no warnings 'experimental::class';

# :does accepted on a class
{
    role Greetable {
        method greet { "hello" }
    }

    class Greeter :does(Greetable) {
        field $name :param;
        method name { $name }
    }

    ok(1, ':does on class compiles');
}

# :does accepted on a role (role-composes-role)
{
    role Inner {
        method inner { "inner" }
    }

    role Outer :does(Inner) {
        method outer { "outer" }
    }

    ok(1, ':does on role compiles');
}

# :does with multiple roles
{
    role R1 {
        method r1 { "r1" }
    }

    role R2 {
        method r2 { "r2" }
    }

    class Multi :does(R1) :does(R2) {
        field $x :param;
        method x { $x }
    }

    ok(1, 'multiple :does on class compiles');
}

# :does rejects non-role targets
{
    ok(!eval q{
        use strict;
        use feature 'class';
        no warnings 'experimental::class';

        class NotARole {
            field $x :param;
        }

        class Consumer :does(NotARole) {
            field $y :param;
        }
        1;
    }, ':does with a class (not role) fails');
    like($@, qr/:does attribute requires a role/, 'correct error for :does with non-role');
}

# :does rejects non-existent packages
{
    ok(!eval q{
        use strict;
        use feature 'class';
        no warnings 'experimental::class';
        class Bad :does(No::Such::Role::Anywhere) { }
        1;
    }, ':does with non-existent package fails');
    ok($@, 'got an error for non-existent role');
}

# :does rejects plain packages
package PlainPkg { sub dummy { 1 } }
{
    ok(!eval q{
        use strict;
        use feature 'class';
        no warnings 'experimental::class';
        class Consumer2 :does(PlainPkg) { }
        1;
    }, ':does with plain package fails');
    like($@, qr/:does attribute requires a role/, 'correct error for :does with plain package');
}

# :does with comma-separated list
{
    role ListR1 {
        method lr1 { "lr1" }
    }

    role ListR2 {
        method lr2 { "lr2" }
    }

    role ListR3 {
        method lr3 { "lr3" }
    }

    class ListConsumer :does(ListR1, ListR2, ListR3) {
        field $x :param;
    }

    my $obj = ListConsumer->new(x => 1);
    is($obj->lr1, 'lr1', ':does list: first role method');
    is($obj->lr2, 'lr2', ':does list: second role method');
    is($obj->lr3, 'lr3', ':does list: third role method');
    ok($obj->DOES('ListR1'), ':does list: DOES first role');
    ok($obj->DOES('ListR2'), ':does list: DOES second role');
    ok($obj->DOES('ListR3'), ':does list: DOES third role');
}

# :does list with fields
{
    role LF1 {
        field $a :param;
        method a { $a }
    }

    role LF2 {
        field $b :param;
        method b { $b }
    }

    class LFConsumer :does(LF1, LF2) {
        field $c :param;
        method c { $c }
    }

    my $obj = LFConsumer->new(a => 1, b => 2, c => 3);
    is($obj->a, 1, ':does list with fields: first role field');
    is($obj->b, 2, ':does list with fields: second role field');
    is($obj->c, 3, ':does list with fields: class field');
}

# :does list with whitespace variations
{
    role WS1 { method ws1 { "ws1" } }
    role WS2 { method ws2 { "ws2" } }

    class WSConsumer :does( WS1 , WS2 ) {
        field $x :param;
    }

    my $obj = WSConsumer->new(x => 1);
    is($obj->ws1, 'ws1', ':does list with whitespace: first role');
    is($obj->ws2, 'ws2', ':does list with whitespace: second role');
}

done_testing;
