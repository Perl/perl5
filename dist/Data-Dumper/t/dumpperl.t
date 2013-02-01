#!./perl -w
# t/dumpperl.t - test all branches of, and modes of triggering, Dumpperl()
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
use Carp;
use Data::Dumper;
$Data::Dumper::Indent=1;
use Test::More tests => 22;
use lib qw( ./t/lib );
use Testing qw( _dumptostr );
my ($a, $b, $obj);
my (@names);
my (@newnames, $objagain, %newnames);
my $dumpstr;
$a = 'alpha';
$b = 'beta';
my @c = ( qw| eta theta | );
my %d = ( iota => 'kappa' );
my $realtype;

local $Data::Dumper::Useperl=1;

note('Data::Dumper::Useperl; names not provided');

$obj = Data::Dumper->new([$a, $b]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+beta/s,
    "Dump: two strings"
);

$obj = Data::Dumper->new([$a, \@c]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+\[.+eta.+theta.+\]/s,
    "Dump: one string, one array ref"
);

$obj = Data::Dumper->new([$a, \%d]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+\{.+iota.+kappa.+\}/s,
    "Dump: one string, one hash ref"
);

$obj = Data::Dumper->new([$a, undef]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+undef/s,
    "Dump: one string, one undef"
);

note('Data::Dumper::Useperl; names provided');

$obj = Data::Dumper->new([$a, $b], [ qw( a b ) ]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$a.+alpha.+\$b.+beta/s,
    "Dump: names: two strings"
);

$obj = Data::Dumper->new([$a, \@c], [ qw( a *c ) ]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$a.+alpha.+\@c.+eta.+theta/s,
    "Dump: names: one string, one array ref"
);

$obj = Data::Dumper->new([$a, \%d], [ qw( a *d ) ]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$a.+alpha.+\%d.+iota.+kappa/s,
    "Dump: names: one string, one hash ref"
);

$obj = Data::Dumper->new([$a,undef], [qw(a *c)]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$a.+alpha.+\$c.+undef/s,
    "Dump: names: one string, one undef"
);

$obj = Data::Dumper->new([$a, $b], [ 'a', '']);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$a.+alpha.+\$.+beta/s,
    "Dump: names: two strings: one name empty"
);

$obj = Data::Dumper->new([$a, $b], [ 'a', '$foo']);
$dumpstr = _dumptostr($obj);
no warnings 'uninitialized';
like($dumpstr,
    qr/\$a.+alpha.+\$foo.+beta/s,
    "Dump: names: two strings: one name start with '\$'"
);
use warnings;

local $Data::Dumper::Useperl=0;

# Setting aside quoting, Useqq should produce same output as Useperl.
# Both will exercise Dumpperl().
# So will run the same tests as above.
note('Data::Dumper::Useqq');

local $Data::Dumper::Useqq=1;

$obj = Data::Dumper->new([$a, $b]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+beta/s,
    "Dump: two strings"
);

$obj = Data::Dumper->new([$a, \@c]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+\[.+eta.+theta.+\]/s,
    "Dump: one string, one array ref"
);

$obj = Data::Dumper->new([$a, \%d]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+\{.+iota.+kappa.+\}/s,
    "Dump: one string, one hash ref"
);

$obj = Data::Dumper->new([$a, undef]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+undef/s,
    "Dump: one string, one undef"
);

local $Data::Dumper::Useqq=0;

# Deparse should produce same output as Useperl.
# Both will exercise Dumpperl().
# So will run the same tests as above.
note('Data::Dumper::Deparse');

local $Data::Dumper::Deparse=1;

$obj = Data::Dumper->new([$a, $b]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+beta/s,
    "Dump: two strings"
);

$obj = Data::Dumper->new([$a, \@c]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+\[.+eta.+theta.+\]/s,
    "Dump: one string, one array ref"
);

$obj = Data::Dumper->new([$a, \%d]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+\{.+iota.+kappa.+\}/s,
    "Dump: one string, one hash ref"
);

$obj = Data::Dumper->new([$a, undef]);
$dumpstr = _dumptostr($obj);
like($dumpstr,
    qr/\$VAR1.+alpha.+\$VAR2.+undef/s,
    "Dump: one string, one undef"
);

local $Data::Dumper::Deparse=0;

{
    my (%dumps, $starting);

    $starting = $Data::Dumper::Useperl;

    local $Data::Dumper::Useperl = 0;
    $obj = Data::Dumper->new([$a, $b]);
    $dumps{'dduzero'} = _dumptostr($obj);

    local $Data::Dumper::Useperl = undef;
    $obj = Data::Dumper->new([$a, $b]);
    $dumps{'dduundef'} = _dumptostr($obj);

    $Data::Dumper::Useperl= $starting;

    $obj = Data::Dumper->new([$a, $b]);
    $obj->Useperl(0);
    $dumps{'useperlzero'} = _dumptostr($obj);

    $obj = Data::Dumper->new([$a, $b]);
    $obj->Useperl(undef);
    $dumps{'useperlundef'} = _dumptostr($obj);

    is($dumps{'dduzero'}, $dumps{'dduundef'},
        "\$Data::Dumper::Useperl(0) and (undef) are equivalent");
    is($dumps{'useperlzero'}, $dumps{'useperlundef'},
        "Useperl(0) and (undef) are equivalent");
    is($dumps{'dduundef'}, $dumps{'useperlundef'},
        "\$Data::Dumper::Useperl(undef) and Useperl(undef) are equivalent");
}

{
    $obj = Data::Dumper->new([ {IO => *{$::{STDERR}}{IO}} ]);
    $obj->Useperl(1);
    eval { $dumpstr = _dumptostr($obj); };
    $realtype = 'IO';
    like($@, qr/Can't handle '$realtype' type/,
        "Got expected error: pure-perl: Data-Dumper does not handle $realtype");
}

