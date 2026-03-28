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

=pod

Tests for error messages and warnings produced by the class system.
Some error cases are also covered in t/lib/croak/class; this file focuses
on runtime errors that are better tested via eval and fresh_perl_like.

=cut

# Cannot bless into a class
{
    class ErrBless1 { }

    eval { bless {}, "ErrBless1" };
    like($@, qr/Attempt to bless into a class/,
        'bless {} into a class is an error');

    eval { bless [], "ErrBless1" };
    like($@, qr/Attempt to bless into a class/,
        'bless [] into a class is an error');

    # Cannot re-bless an object into something else
    my $obj = ErrBless1->new;
    eval { bless $obj, "main" };
    like($@, qr/Can't bless an object reference/,
        'Cannot re-bless a class instance');
}

# Cannot reopen a sealed class
{
    class ErrReopen1 { }
    ok(!eval q{ class ErrReopen1 { } 1; },
        'Reopening a sealed class is an error');
    like($@, qr/Cannot reopen existing class/,
        'Error message for reopening sealed class');
}

# @ISA of a class is read-only
{
    class ErrISA1 { }
    eval { push @ErrISA1::ISA, "SomeClass" };
    like($@, qr/Modification of a read-only value/,
        'push to @ISA of class fails');

    eval { @ErrISA1::ISA = () };
    like($@, qr/Modification of a read-only value/,
        'assignment to @ISA of class fails');
}

# Cross-class method invocation
{
    class ErrCross1 {
        method x { "x" }
    }
    class ErrCross2 {
        method y { "y" }
    }

    my $obj1 = ErrCross1->new;
    eval { $obj1->ErrCross2::y() };
    like($@, qr/Cannot invoke a method of "ErrCross2" on an instance of "ErrCross1"/,
        'Cross-class method invocation error');
}

# Method invoked on non-instance values
{
    class ErrNonInst1 {
        method m { "m" }
    }

    # No args (bare function call)
    eval { ErrNonInst1::m() };
    like($@, qr/Cannot invoke method "m" on a non-instance/,
        'Method called with no args (not as method)');

    # Non-reference
    eval { ErrNonInst1::m(42) };
    like($@, qr/Cannot invoke method "m" on a non-instance/,
        'Method called with non-ref arg');

    # Unblessed reference
    eval { ErrNonInst1::m([]) };
    like($@, qr/Cannot invoke method "m" on a non-instance/,
        'Method called with unblessed ref');
}

# Unrecognized constructor parameter
{
    class ErrParam1 {
        field $x :param;
    }

    eval { ErrParam1->new(x => 1, bogus => 2) };
    like($@, qr/Unrecognized parameters for "ErrParam1" constructor: bogus/,
        'Unrecognized parameter in constructor');

    eval { ErrParam1->new(x => 1, bogus => 2, other => 3) };
    like($@, qr/Unrecognized parameters for "ErrParam1" constructor:/,
        'Multiple unrecognized parameters in constructor');
}

# Required parameter missing
{
    class ErrReq1 {
        field $a :param;
        field $b :param;
    }

    eval { ErrReq1->new(a => 1) };
    like($@, qr/Required parameter 'b' is missing for "ErrReq1" constructor/,
        'Missing required parameter error');

    eval { ErrReq1->new() };
    like($@, qr/Required parameter '\w+' is missing for "ErrReq1" constructor/,
        'All required parameters missing');
}

# Odd number of arguments to constructor
{
    class ErrOdd1 {
        field $x :param = undef;
    }

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    eval { ErrOdd1->new("lonely") };
    ok(grep(/Odd/, @warnings), 'Odd number of constructor args produces warning');
}

# Duplicate :param name within same class
{
    ok(!eval q{
        class ErrDupParam1 {
            field $x :param(same);
            field $y :param(same);
        }
        1;
    }, 'Duplicate :param name in same class is an error');
    like($@, qr/already in use/,
        'Error mentions name conflict for duplicate :param');
}

# Duplicate :param name across inheritance
{
    ok(!eval q{
        class ErrDupParamBase1 {
            field $x :param(shared);
        }
        class ErrDupParamChild1 :isa(ErrDupParamBase1) {
            field $y :param(shared);
        }
        1;
    }, 'Duplicate :param across inheritance is an error');
    like($@, qr/already in use/,
        'Error mentions name conflict for inherited :param');
}

# :writer on non-scalar field
{
    ok(!eval q{
        class ErrWriterArr1 {
            field @x :writer;
        }
        1;
    }, ':writer on array field is an error');
    like($@, qr/Cannot apply a :writer attribute to a non-scalar field/,
        'Error for :writer on array field');

    ok(!eval q{
        class ErrWriterHash1 {
            field %x :writer;
        }
        1;
    }, ':writer on hash field is an error');
    like($@, qr/Cannot apply a :writer attribute to a non-scalar field/,
        'Error for :writer on hash field');
}

# Invalid method name for :reader
{
    ok(!eval q{
        class ErrReaderName1 {
            field $x :reader(not-valid);
        }
        1;
    }, 'Invalid :reader name is an error');
    like($@, qr/is not a valid name for a generated method/,
        'Error for invalid :reader name');
}

# Invalid method name for :writer
{
    ok(!eval q{
        class ErrWriterName1 {
            field $x :writer(not-valid);
        }
        1;
    }, 'Invalid :writer name is an error');
    like($@, qr/is not a valid name for a generated method/,
        'Error for invalid :writer name');
}

# Cannot create incomplete class object
{
    eval q{ class ErrIncomplete1 { } 1; };

    # Force an incomplete class via interrupted compilation
    eval 'class ErrIncomplete2 {';  # parse error, class left incomplete
    eval { ErrIncomplete2->new };
    # Should fail - either "Can't locate object method" or "incomplete class"
    ok($@, 'Cannot create object of class with failed parse');
}

# __CLASS__ outside of class context
{
    ok(!eval q{
        class ErrClassToken1 {
            my $x = __CLASS__;
        }
        1;
    }, '__CLASS__ outside method or field init is an error');
    like($@, qr/Cannot use __CLASS__ outside of a method or field initializer expression/,
        'Error message for __CLASS__ in wrong context');
}

# Field access outside method
{
    ok(!eval q{
        class ErrFieldAccess1 {
            field $secret;
            $secret = 123;
        }
        1;
    }, 'Field access outside method is an error');
    like($@, qr/Field \$secret is not accessible outside a method/,
        'Error message for field access outside method');
}

# Field access from a regular sub (not a method)
{
    ok(!eval q{
        class ErrFieldSub1 {
            field $x;
            sub peek { return $x }
        }
        1;
    }, 'Field access from sub (not method) is an error');
    like($@, qr/Field \$x is not accessible outside a method/,
        'Error for field in sub');
}

# Field access from nested class
{
    ok(!eval q{
        class ErrFieldNested1 {
            field $x;
            class ErrFieldNested2 {
                method peek { return $x }
            }
        }
        1;
    }, 'Field access from different class method is an error');
    like($@, qr/Field \$x of "ErrFieldNested1" is not accessible in a method of "ErrFieldNested2"/,
        'Error for field access from nested class method');
}

# Superclass that is not a class
# (:isa auto-requires, so pre-populate stash and %INC in BEGIN)
{
    BEGIN {
        package ErrNotAClass1;
        sub hello { 1 }
        $INC{"ErrNotAClass1.pm"} = 1;
    }

    ok(!eval q{
        class ErrIsaNotClass1 :isa(ErrNotAClass1) { }
        1;
    }, ':isa with non-class package is an error');
    like($@, qr/requires a class but "ErrNotAClass1" is not one/,
        'Error for :isa with non-class');
}

# Class already has a superclass
{
    class ErrMultiIsa1 { }
    class ErrMultiIsa2 { }

    ok(!eval q{
        class ErrMultiIsaChild1 :isa(ErrMultiIsa1) :isa(ErrMultiIsa2) { }
        1;
    }, 'Multiple :isa attributes is an error');
    like($@, qr/Class already has a superclass/,
        'Error for multiple :isa');
}

# Unrecognized class attribute
{
    ok(!eval q{
        class ErrBadAttr1 :bogus { }
        1;
    }, 'Unrecognized class attribute is an error');
    like($@, qr/Unrecognized class attribute/,
        'Error for unrecognized class attribute');
}

# Unrecognized field attribute
{
    ok(!eval q{
        class ErrBadFieldAttr1 {
            field $x :bogus;
        }
        1;
    }, 'Unrecognized field attribute is an error');
    like($@, qr/Unrecognized field attribute/,
        'Error for unrecognized field attribute');
}

# Pre-existing @ISA prevents class creation
{
    BEGIN { @ErrPreISA1::ISA = ("Something"); }
    ok(!eval q{
        class ErrPreISA1 { }
        1;
    }, 'Class with pre-existing @ISA is an error');
    like($@, qr/already has a non-empty \@ISA/,
        'Error for pre-existing @ISA');
}

done_testing;
