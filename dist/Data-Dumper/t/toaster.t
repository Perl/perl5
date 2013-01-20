#!./perl -w
# t/toaster.t - Test Toaster()

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
use Test::More tests =>  8;
use lib qw( ./t/lib );
use Testing qw( _dumptostr );

my %d = (
    delta   => 'd',
    beta    => 'b',
    gamma   => 'c',
    alpha   => 'a',
);

{
    my ($obj, %dumps, $toaster, $starting);

    note("\$Data::Dumper::Toaster and Toaster() set to true value");
    note("XS implementation");
    $Data::Dumper::Useperl = 0;

    $starting = $Data::Dumper::Toaster;
    $toaster = 1;
    local $Data::Dumper::Toaster = $toaster;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddtoasterone'} = _dumptostr($obj);
    local $Data::Dumper::Toaster = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Toaster($toaster);
    $dumps{'objtoasterone'} = _dumptostr($obj);

    is($dumps{'ddtoasterone'}, $dumps{'objtoasterone'},
        "\$Data::Dumper::Toaster = 1 and Toaster(1) are equivalent");
    %dumps = ();

    $toaster = 0;
    local $Data::Dumper::Toaster = $toaster;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddtoasterzero'} = _dumptostr($obj);
    local $Data::Dumper::Toaster = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Toaster($toaster);
    $dumps{'objtoasterzero'} = _dumptostr($obj);

    is($dumps{'ddtoasterzero'}, $dumps{'objtoasterzero'},
        "\$Data::Dumper::Toaster = 0 and Toaster(0) are equivalent");

    $toaster = undef;
    local $Data::Dumper::Toaster = $toaster;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddtoasterundef'} = _dumptostr($obj);
    local $Data::Dumper::Toaster = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Toaster($toaster);
    $dumps{'objtoasterundef'} = _dumptostr($obj);

    is($dumps{'ddtoasterundef'}, $dumps{'objtoasterundef'},
        "\$Data::Dumper::Toaster = undef and Toaster(undef) are equivalent");
    is($dumps{'ddtoasterzero'}, $dumps{'objtoasterundef'},
        "\$Data::Dumper::Toaster = undef and = 0 are equivalent");
    %dumps = ();

    note("Perl implementation");
    $Data::Dumper::Useperl = 1;

    $starting = $Data::Dumper::Toaster;
    $toaster = 1;
    local $Data::Dumper::Toaster = $toaster;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddtoasterone'} = _dumptostr($obj);
    local $Data::Dumper::Toaster = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Toaster($toaster);
    $dumps{'objtoasterone'} = _dumptostr($obj);

    is($dumps{'ddtoasterone'}, $dumps{'objtoasterone'},
        "\$Data::Dumper::Toaster = 1 and Toaster(1) are equivalent");
    %dumps = ();

    $toaster = 0;
    local $Data::Dumper::Toaster = $toaster;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddtoasterzero'} = _dumptostr($obj);
    local $Data::Dumper::Toaster = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Toaster($toaster);
    $dumps{'objtoasterzero'} = _dumptostr($obj);

    is($dumps{'ddtoasterzero'}, $dumps{'objtoasterzero'},
        "\$Data::Dumper::Toaster = 0 and Toaster(0) are equivalent");

    $toaster = undef;
    local $Data::Dumper::Toaster = $toaster;
    $obj = Data::Dumper->new( [ \%d ] );
    $dumps{'ddtoasterundef'} = _dumptostr($obj);
    local $Data::Dumper::Toaster = $starting;

    $obj = Data::Dumper->new( [ \%d ] );
    $obj->Toaster($toaster);
    $dumps{'objtoasterundef'} = _dumptostr($obj);

    is($dumps{'ddtoasterundef'}, $dumps{'objtoasterundef'},
        "\$Data::Dumper::Toaster = undef and Toaster(undef) are equivalent");
    is($dumps{'ddtoasterzero'}, $dumps{'objtoasterundef'},
        "\$Data::Dumper::Toaster = undef and = 0 are equivalent");
    %dumps = ();

}

