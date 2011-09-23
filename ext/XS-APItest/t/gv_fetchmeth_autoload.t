#!perl

use strict;
use warnings;

use Test::More tests => 35;

use_ok('XS::APItest');

my $level = -1;
my @types = map { 'gv_fetchmeth' . $_ . "_autoload" } '', qw( _sv _pv _pvn );

sub test { "Sanity check" }

for my $type ( 0..3 ) {
    is *{XS::APItest::gv_fetchmeth_autoload_type(
           \%::, "test", $type, $level, 0
        )}{CODE}->(), "Sanity check";
}

{
    ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, "etc", 1, $level, 0), "fails when the glob doesn't exist and AUTOLOAD is undefined,";
    local *AUTOLOAD = sub { 1 };
    is XS::APItest::gv_fetchmeth_autoload_type(\%::, "etc", 1, $level, 0), "*main::etc", "..but defining AUTOLOAD makes it succeed.";
}

for my $type ( 0..3 ) {
    my $meth = "gen$type";
    ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, $meth, $type, -1, 0), "With level = -1, $types[$type] returns false.";
    ok !$::{$meth}, "...and doesn't vivify the glob.";

    ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, $meth, $type, 0, 0), "With level = 0, $types[$type] still returns false.";
    ok $::{$meth}, "...but does vivify the glob.";

    ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, $meth . $type, $type, $level, 0), "$types[$type] fails when the glob doesn't exist and AUTOLOAD is undefined,";
    local *AUTOLOAD = sub { 1 };
    is XS::APItest::gv_fetchmeth_autoload_type(\%::, $meth . $type, $type, $level, 0), "*main::$meth$type", "..but defining AUTOLOAD makes it succeed.";
}

{
    no warnings 'once';
    *method = sub { 1 };
}

ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, "method\0not quite!", 0, $level, 0), "gv_fetchmeth() is nul-clean";
ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, "method\0not quite!", 1, $level, 0), "gv_fetchmeth_autoload_sv() is nul-clean";
is XS::APItest::gv_fetchmeth_autoload_type(\%::, "method\0not quite!", 2, $level, 0), "*main::method", "gv_fetchmeth_autoload_pv() is not nul-clean";
ok !XS::APItest::gv_fetchmeth_autoload_type(\%::, "method\0not quite!", 3, $level, 0), "gv_fetchmeth_autoload_pvn() is nul-clean";

