#!./perl -w
# t/quotekeys.t - Test Quotekeys()

BEGIN {
    if ($ENV{PERL_CORE}){
        require Config; import Config;
        no warnings 'once';
        if ($Config{'extensions'} !~ /\bData\/Dumper\b/) {
            print "1..0 # Skip: Data::Dumper was not built\n";
            exit 0;
        }
    }
}

use strict;

use Data::Dumper;
use Test::More tests => 10;
use lib qw( ./t/lib );
use Testing qw( _dumptostr );

my %d = (
    delta   => 'd',
    beta    => 'b',
    gamma   => 'c',
    alpha   => 'a',
);

{
    my ($obj, %dumps, $quotekeys, $starting);

    note("\$Data::Dumper::Quotekeys and Quotekeys() set to true value");
    note("XS implementation");
    $Data::Dumper::Useperl = 0;

    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkdefault'} = _dumptostr($obj);

    $starting = $Data::Dumper::Quotekeys;
    $quotekeys = 1;
    local $Data::Dumper::Quotekeys = $quotekeys;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkone'} = _dumptostr($obj);
    local $Data::Dumper::Quotekeys = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Quotekeys($quotekeys);
    $dumps{'objqkone'} = _dumptostr($obj);

    is($dumps{'ddqkdefault'}, $dumps{'ddqkone'},
        "\$Data::Dumper::Quotekeys = 1 is default");
    is($dumps{'ddqkone'}, $dumps{'objqkone'},
        "\$Data::Dumper::Quotekeys = 1 and Quotekeys(1) are equivalent");
    %dumps = ();

    $quotekeys = 0;
    local $Data::Dumper::Quotekeys = $quotekeys;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkzero'} = _dumptostr($obj);
    local $Data::Dumper::Quotekeys = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Quotekeys($quotekeys);
    $dumps{'objqkzero'} = _dumptostr($obj);

    is($dumps{'ddqkzero'}, $dumps{'objqkzero'},
        "\$Data::Dumper::Quotekeys = 0 and Quotekeys(0) are equivalent");

    $quotekeys = undef;
    local $Data::Dumper::Quotekeys = $quotekeys;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkundef'} = _dumptostr($obj);
    local $Data::Dumper::Quotekeys = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Quotekeys($quotekeys);
    $dumps{'objqkundef'} = _dumptostr($obj);

    note("Quotekeys(undef) will fall back to the default value\nfor \$Data::Dumper::Quotekeys, which is a true value.");
    isnt($dumps{'ddqkundef'}, $dumps{'objqkundef'},
        "\$Data::Dumper::Quotekeys = undef and Quotekeys(undef) are equivalent");
    isnt($dumps{'ddqkzero'}, $dumps{'objqkundef'},
        "\$Data::Dumper::Quotekeys = undef and = 0 are equivalent");
    %dumps = ();

    note("Perl implementation");
    $Data::Dumper::Useperl = 1;

    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkdefault'} = _dumptostr($obj);

    $starting = $Data::Dumper::Quotekeys;
    $quotekeys = 1;
    local $Data::Dumper::Quotekeys = $quotekeys;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkone'} = _dumptostr($obj);
    local $Data::Dumper::Quotekeys = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Quotekeys($quotekeys);
    $dumps{'objqkone'} = _dumptostr($obj);

    is($dumps{'ddqkundef'}, $dumps{'objqkundef'},
        "\$Data::Dumper::Quotekeys = undef and Quotekeys(undef) are equivalent");
    is($dumps{'ddqkone'}, $dumps{'objqkone'},
        "\$Data::Dumper::Quotekeys = 1 and Quotekeys(1) are equivalent");
    %dumps = ();

    $quotekeys = 0;
    local $Data::Dumper::Quotekeys = $quotekeys;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkzero'} = _dumptostr($obj);
    local $Data::Dumper::Quotekeys = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Quotekeys($quotekeys);
    $dumps{'objqkzero'} = _dumptostr($obj);

    is($dumps{'ddqkzero'}, $dumps{'objqkzero'},
        "\$Data::Dumper::Quotekeys = 0 and Quotekeys(0) are equivalent");

    $quotekeys = undef;
    local $Data::Dumper::Quotekeys = $quotekeys;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddqkundef'} = _dumptostr($obj);
    local $Data::Dumper::Quotekeys = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Quotekeys($quotekeys);
    $dumps{'objqkundef'} = _dumptostr($obj);

    note("Quotekeys(undef) will fall back to the default value\nfor \$Data::Dumper::Quotekeys, which is a true value.");
    isnt($dumps{'ddqkundef'}, $dumps{'objqkundef'},
        "\$Data::Dumper::Quotekeys = undef and Quotekeys(undef) are equivalent");
    isnt($dumps{'ddqkzero'}, $dumps{'objqkundef'},
        "\$Data::Dumper::Quotekeys = undef and = 0 are equivalent");
    %dumps = ();
}

