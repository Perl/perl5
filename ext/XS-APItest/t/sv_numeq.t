#!perl

use Test::More tests => 25;
use XS::APItest;
use Config;

my $four = 4;
ok  sv_numeq($four, 4), '$four == 4';
ok !sv_numeq($four, 5), '$four != 5';

SKIP:
{
    no warnings 'experimental';
    my $nan = eval { builtin::nan };
    defined $nan
      or skip "No NAN", 2;
    my $nan = 0+"NaN";
    ok !sv_numeq($nan, 0),  '$nan != 0';
    ok !sv_numeq($nan, $nan), '$nan != $nan';
}

my $six_point_five = 6.5; # an exact float, so == is fine
ok  sv_numeq($six_point_five, 6.5), '$six_point_five == 6.5';
ok !sv_numeq($six_point_five, 6.6), '$six_point_five != 6.6';

# NULLs
ok sv_numeq(undef, 0), "NULL sv1";
ok sv_numeq(0, undef), "NULL sv2";

# GMAGIC
"10" =~ m/(\d+)/;
ok !sv_numeq_flags($1, 10, 0), 'sv_numeq_flags with no flags does not GETMAGIC';
ok  sv_numeq_flags($1, 10, SV_GMAGIC), 'sv_numeq_flags with SV_GMAGIC does';

# overloading
{
    package AlwaysTen {
        use overload
            '==' => sub { return $_[1] == 10 },
            '0+' => sub { 123456 };
    }
    my $obj = bless([], "AlwaysTen");

    ok  sv_numeq($obj, 10), 'AlwaysTen is 10';
    ok !sv_numeq($obj, 11), 'AlwaysTen is not 11';
    ok  sv_numeq(10, $obj), 'AlwaysTen is 10 on the right';
    ok !sv_numeq(11, $obj), 'AlwaysTen is not 11 on the right';

    ok !sv_numeq_flags($obj, 10, SV_SKIP_OVERLOAD), 'AlwaysTen is not 10 with SV_SKIP_OVERLOAD';
    ok !sv_numeq_flags($obj, 123456, SV_SKIP_OVERLOAD), 'AlwaysTen is not its overloaded numeric value with SV_SKIP_OVERLOAD';

    my $result;
    void_sv_numeq($obj, 10, $result);
    ok($result, "overloaded sv_numeq() (eq) in void context");
    void_sv_numeq($obj, 12, $result);
    ok(!$result, "overloaded sv_numeq() (ne) in void context");
}

# +0 overloading with large numbers and using fallback
{
    my $big = ~0;
    my $bigm1 = $big-1;
    package MyBigNum {
        use overload "0+" => sub { $_[0][0] },
          fallback => 1;
    }
    my $o1 = bless [ $big   ], "MyBigNum";
    my $o2 = bless [ $big   ], "MyBigNum";
    my $o3 = bless [ $bigm1 ], "MyBigNum";

    ok $o1 == $o2, "perl op gets it right";
    ok $o1 == $big, "perl op still gets it right for left overload";
    ok !($o1 == $o3), "perl op still gets it right for different values";
    ok sv_numeq($o1, $o2), "sv_numeq two overloads";
    ok !sv_numeq($o1, $o3), "sv_numeq two different overloads"
      or diag sprintf "%x vs %x", $o1, $o3;
    ok sv_numeq($o1, $big), "sv_numeq left overload";
    ok sv_numeq($bigm1, $o3), "sv_numeq right overload";
}
