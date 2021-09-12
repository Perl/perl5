#!perl

use Test::More tests => 6;
use XS::APItest;

my $four = 4;
ok  sv_numeq($four, 4), '$four == 4';
ok !sv_numeq($four, 5), '$four != 5';

my $six_point_five = 6.5; # an exact float, so == is fine
ok  sv_numeq($six_point_five, 6.5), '$six_point_five == 6.5';
ok !sv_numeq($six_point_five, 6.6), '$six_point_five == 6.6';

# GMAGIC
"10" =~ m/(\d+)/;
ok !sv_numeq_flags($1, 10, 0), 'sv_numeq_flags with no flags does not GETMAGIC';
ok  sv_numeq_flags($1, 10, SV_GMAGIC), 'sv_numeq_flags with SV_GMAGIC does';
