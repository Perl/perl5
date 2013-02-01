#!./perl -w
#
# test a few problems with the Freezer option, not a complete Freezer
# test suite yet

BEGIN {
    require Config; import Config;
    no warnings 'once';
    if ($Config{'extensions'} !~ /\bData\/Dumper\b/) {
	print "1..0 # Skip: Data::Dumper was not built\n";
	exit 0;
    }
}

use strict;
use Test::More tests => 15;
use Data::Dumper;
use lib qw( ./t/lib );
use Testing qw( _dumptostr );

{
    local $Data::Dumper::Freezer = 'freeze';

    # test for seg-fault bug when freeze() returns a non-ref
    {
        my $foo = Test1->new("foo");
        my $dumped_foo = Dumper($foo);
        ok($dumped_foo,
           "Use of freezer sub which returns non-ref worked.");
        like($dumped_foo, qr/frozed/,
             "Dumped string has the key added by Freezer with useperl.");
        like(join(" ", Dumper($foo)), qr/\A\$VAR1 = /,
             "Dumped list doesn't begin with Freezer's return value with useperl");
    }

    # run the same tests with useperl.  this always worked
    {
        local $Data::Dumper::Useperl = 1;
        my $foo = Test1->new("foo");
        my $dumped_foo = Dumper($foo);
        ok($dumped_foo,
           "Use of freezer sub which returns non-ref worked with useperl");
        like($dumped_foo, qr/frozed/,
             "Dumped string has the key added by Freezer with useperl.");
        like(join(" ", Dumper($foo)), qr/\A\$VAR1 = /,
             "Dumped list doesn't begin with Freezer's return value with useperl");
    }

    # test for warning when an object does not have a freeze()
    {
        my $warned = 0;
        local $SIG{__WARN__} = sub { $warned++ };
        my $bar = Test2->new("bar");
        my $dumped_bar = Dumper($bar);
        is($warned, 0, "A missing freeze() shouldn't warn.");
    }

    # run the same test with useperl, which always worked
    {
        local $Data::Dumper::Useperl = 1;
        my $warned = 0;
        local $SIG{__WARN__} = sub { $warned++ };
        my $bar = Test2->new("bar");
        my $dumped_bar = Dumper($bar);
        is($warned, 0, "A missing freeze() shouldn't warn with useperl");
    }

    # a freeze() which die()s should still trigger the warning
    {
        my $warned = 0;
        local $SIG{__WARN__} = sub { $warned++; };
        my $bar = Test3->new("bar");
        my $dumped_bar = Dumper($bar);
        is($warned, 1, "A freeze() which die()s should warn.");
    }

    # the same should work in useperl
    {
        local $Data::Dumper::Useperl = 1;
        my $warned = 0;
        local $SIG{__WARN__} = sub { $warned++; };
        my $bar = Test3->new("bar");
        my $dumped_bar = Dumper($bar);
        is($warned, 1, "A freeze() which die()s should warn with useperl.");
    }
}

{
    my ($obj, %dumps);
    my $foo = Test1->new("foo");

    local $Data::Dumper::Freezer = 'freeze';
    $obj = Data::Dumper->new( [ $foo ] );
    $dumps{'ddftrue'} = _dumptostr($obj);
    local $Data::Dumper::Freezer = '';

    $obj = Data::Dumper->new( [ $foo ] );
    $obj->Freezer('freeze');
    $dumps{'objset'} = _dumptostr($obj);

    is($dumps{'ddftrue'}, $dumps{'objset'},
        "\$Data::Dumper::Freezer and Freezer() are equivalent");
}

{
    my ($obj, %dumps);
    my $foo = Test1->new("foo");

    local $Data::Dumper::Freezer = 'freeze';

    local $Data::Dumper::Useperl = 1;
    $obj = Data::Dumper->new( [ $foo ] );
    $dumps{'ddftrueuseperl'} = _dumptostr($obj);

    local $Data::Dumper::Useperl = 0;
    $obj = Data::Dumper->new( [ $foo ] );
    $dumps{'ddftruexs'} = _dumptostr($obj);

    is( $dumps{'ddftruexs'}, $dumps{'ddftrueuseperl'},
        "\$Data::Dumper::Freezer() gives same results under XS and Useperl");
}

{
    my ($obj, %dumps);
    my $foo = Test1->new("foo");

    local $Data::Dumper::Useperl = 1;
    $obj = Data::Dumper->new( [ $foo ] );
    $obj->Freezer('freeze');
    $dumps{'objsetuseperl'} = _dumptostr($obj);

    local $Data::Dumper::Useperl = 0;
    $obj = Data::Dumper->new( [ $foo ] );
    $obj->Freezer('freeze');
    $dumps{'objsetxs'} = _dumptostr($obj);

    is($dumps{'objsetxs'}, $dumps{'objsetuseperl'},
        "Freezer() gives same results under XS and Useperl");
}

{
    my ($obj, %dumps);
    my $foo = Test1->new("foo");

    local $Data::Dumper::Freezer = '';
    $obj = Data::Dumper->new( [ $foo ] );
    $dumps{'ddfemptystr'} = _dumptostr($obj);

    local $Data::Dumper::Freezer = undef;
    $obj = Data::Dumper->new( [ $foo ] );
    $dumps{'ddfundef'} = _dumptostr($obj);

    is($dumps{'ddfundef'}, $dumps{'ddfemptystr'},
        "\$Data::Dumper::Freezer same with empty string or undef");
}

{
    my ($obj, %dumps);
    my $foo = Test1->new("foo");

    $obj = Data::Dumper->new( [ $foo ] );
    $obj->Freezer('');
    $dumps{'objemptystr'} = _dumptostr($obj);

    $obj = Data::Dumper->new( [ $foo ] );
    $obj->Freezer(undef);
    $dumps{'objundef'} = _dumptostr($obj);

    is($dumps{'objundef'}, $dumps{'objemptystr'},
        "Freezer() same with empty string or undef");
}


# a package with a freeze() which returns a non-ref
package Test1;
sub new { bless({name => $_[1]}, $_[0]) }
sub freeze {
    my $self = shift;
    $self->{frozed} = 1;
}

# a package without a freeze()
package Test2;
sub new { bless({name => $_[1]}, $_[0]) }

# a package with a freeze() which dies
package Test3;
sub new { bless({name => $_[1]}, $_[0]) }
sub freeze { die "freeze() is broken" }
