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
    role Test1Role { # simple empty role
    }

    class Test1 :does(Test1Role) {
        method hello { return "hello, world"; }

        method classname { return __CLASS__; }
    }

    my $obj = Test1->new;
    isa_ok($obj, "Test1", '$obj');

    is($obj->hello, "hello, world", '$obj->hello');

    is($obj->classname, "Test1", '$obj->classname yields __CLASS__');
}

# Roles can provide methods
{
    role Test2Role {
        method hello { return "hello, world"; }
        method classname :common { return __CLASS__; }
    }

    class Test2 :does(Test2Role) {
    }

    my $obj = Test2->new;
    isa_ok($obj, "Test2", '$obj');

    is($obj->hello, "hello, world", '$obj->hello');

    # TODO This one is seemingly working based on what I see with Object::Pad but because it's not the core class feature it's not producing the result I expect.  discuss, -rv
    is(Test2->classname, "Test2", 'Test2->classname yields __CLASS__');
}

# Roles can require methods
{
    role Test3Role {
      method hello;
    }

    class Test3a :does(Test3Role) {
        method hello { return "hello, world"; }
    }

    my $obj = Test3a->new;
    isa_ok($obj, "Test3a", '$obj');

    is($obj->hello, "hello, world", '$obj->hello');

    my $result = eval q{
      class Test3b :does(Test3Role) {
      }; 42
    };

    my $error = $@;

    isnt($result, 42, "Class without required method succceeds");
    # TBD fully proper error message, for now copied from how Object::Pad produces it
    is($error, "Class Test3b does not provide a required method named 'hello' at (eval 14) line 3.\n", "Correct error message when class is missing required method");
}


# Roles can have fields
{
    role Test4Role {
        field $world;
        field $default = "default value";

        method hello { return $default; }
    }
    
    role Test4RoleB {
        field $world :param;

        method hello { return $world; }
    }

    class Test4 :does(Test4Role) {
    }
    
    class Test4B :does(Test4RoleB) {
    }

    my $obj = Test4->new;
    isa_ok($obj, "Test4", '$obj');

    is($obj->hello, "default value", '$obj->hello');
    
    my $obj = Test4B->new(world => "HELLO!");
    isa_ok($obj, "Test4B", '$obj');

    is($obj->hello, "HELLO!", '$obj->hello');
}

# Multiple roles can be consumed
{
    role Test5RoleA {
        field $A;

        method hello { return "hello world!" }
    }
    
    role Test5RoleB {
        field $world :param;

        method methodB { return $world; }
    }

    class Test5 :does(Test5RoleA) :does(Test5RoleB) {
    }
    
    my $obj = Test5->new(world => "the answer is 42");
    isa_ok($obj, "Test5", '$obj');

    is($obj->hello, "hello world!", '$obj->hello');
    
    is($obj->methodB, "the answer is 42", '$obj->methodB');
}

# Multiple roles can consume roles
{
    role Test6RoleA {
        field $A;

        method hello { return "hello world!" }
    }
    
    role Test6RoleB :does(Test6RoleA) {
        field $world :param;

        method methodB { return $world; }
    }

    class Test6 :does(Test6RoleB) {
    }
    
    my $obj = Test6->new(world => "the answer is 42");
    isa_ok($obj, "Test6", '$obj');

    is($obj->hello, "hello world!", '$obj->hello');
    
    is($obj->methodB, "the answer is 42", '$obj->methodB');
}

done_testing;
