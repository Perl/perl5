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

# A legacy-perl class to act as a test helper
package DestructionNotify {
    sub new { my $pkg = shift; bless [ @_ ], $pkg }
    sub DESTROY { my $self = shift; ${ $self->[0] } .= $self->[1] }
}

{
    my $destroyed;
    my $notifier = DestructionNotify->new( \$destroyed, 1 );
    undef $notifier;
    $destroyed or
        BAIL_OUT('DestructionNotify does not work');
}

{
    my $destroyed;

    class Testcase1 {
        field $x;
        method x { return $x; }
        ADJUST {
            $x = DestructionNotify->new( \$destroyed, "x" );
        }

        field $y;
        field $z;
        ADJUST {
            # These in the "wrong" order just to prove to ourselves that it
            # doesn't matter
            $z = DestructionNotify->new( \$destroyed, "z" );
            $y = DestructionNotify->new( \$destroyed, "y" );
        }
    }

    my $obj = Testcase1->new;
    ok(!$destroyed, 'Destruction notify not yet triggered');

    refcount_is $obj, 1, 'Object has one reference';

    # one in $obj, one stack temporary here
    refcount_is $obj->x, 2, 'DestructionNotify has two references';

    undef $obj;
    is($destroyed, "zyx", 'Destruction notify triggered by object destruction in the correct order');
}

# GH22278
{
    my $observed;

    class Testcase2 {
        field $f1 :param :reader;
        field $f2 :param :reader;
        method DESTROY {
            $observed = $f1;
        }
    }

    my $e = eval { Testcase2->new( f1 => "field 1" ); 1 } ? undef : $@;
    pass('Testcase2 constructor did not segfault');
    like($e, qr/^Required parameter 'f2' is missing for "Testcase2" constructor at /,
        'Constructor throws but does not crash');
    is($observed, "field 1", 'Prior field is still initialised correctly');
}

done_testing;
