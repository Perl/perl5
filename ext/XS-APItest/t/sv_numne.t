#!perl

use Test::More tests => 34;
use XS::APItest;
use Config;

my $four = 4;
ok !sv_numne($four, 4), '$four == 4'; # not(not equal)
ok  sv_numne($four, 5), '$four != 5';

SKIP:
{
    no warnings 'experimental';
    my $nan = eval { builtin::nan };
    defined $nan
      or skip "No NAN", 2;
    ok  sv_numne($nan, 0),  '$nan != 0';
    ok  sv_numne($nan, $nan), '$nan != $nan';
}

my $six_point_five = 6.5; # an exact float, so == is fine
ok !sv_numne($six_point_five, 6.5), '$six_point_five == 6.5';
ok  sv_numne($six_point_five, 6.6), '$six_point_five != 6.6';

# NULLs
ok sv_numne(undef, 1), "NULL sv1";
ok sv_numne(1, undef), "NULL sv2";

# GMAGIC
"11" =~ m/(\d+)/;
ok  sv_numne_flags($1, 11, 0), 'sv_numne_flags with no flags does not GETMAGIC';
ok !sv_numne_flags($1, 11, SV_GMAGIC), 'sv_numne_flags with SV_GMAGIC does';

{
    package AlwaysTwelve {
        use overload
            '!=' => sub { return $_[1] != 12 },
            '0+' => sub { 11 };
    }
    my $obj = bless([], "AlwaysTwelve");

    ok !sv_numne($obj, 12), 'AlwaysTwelve is 12';
    ok  sv_numne($obj, 11), 'AlwaysTwelve is not 11';
    ok !sv_numne(12, $obj), 'AlwaysTwelve is 12 on right';
    ok  sv_numne(11, $obj), 'AlwayeTwelve is not 11 on the right';

    # neither '!=' nor '0+' overloading applies
    ok sv_numne_flags($obj, 11, SV_SKIP_OVERLOAD), 'AlwaysTwelve is not 11 with SV_SKIP_OVERLOAD';
    ok sv_numne_flags($obj, 12, SV_SKIP_OVERLOAD), 'AlwaysTwelve is not 12 with SV_SKIP_OVERLOAD';

    my $result;
    void_sv_numne($obj, 11, $result);
    ok($result, "overloaded sv_numne() (ne) in void context");
    void_sv_numne($obj, 12, $result);
    ok(!$result, "overloaded sv_numne() (eq) in void context");

    no overloading;
    ok sv_numne($obj, 11), 'AlwaysTwelve is not 11 with no overloading (api)';
    ok $obj != 11, 'AlwaysTwelve is not 11 with no overloading (op)';

    ok sv_numne($obj, 12), 'AlwaysTwelve is not 12 with no overloading (api)';
    ok $obj != 12, 'AlwaysTwelve is not 12 with no overloading (op)';

    ok !sv_numne_flags($obj, 12, SV_FORCE_OVERLOAD), 'AlwaysTwelve is 12 with no overloading and SV_FORCE_OVERLOAD';
    use overloading;
    no overloading '!=';
    ok !sv_numne($obj, 11), 'AlwaysTwelve is 11 with no overloading "!=" (api)';
    ok !($obj != 11), 'AlwaysTwelve is 11 with no overloading "!=" (op)';
    ok sv_numne($obj, 12), 'AlwaysTwelve is not 12 with no overloading "!=" (api)';
    ok $obj != 12, 'AlwaysTwelve is not 12 with no overloading "!=" (op)';
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

    ok !($o1 != $o2), "perl op gets it right";
    ok $o1 != $bigm1, "perl op still gets it right for left overload";
    ok $o1 != $o3, "perl op still gets it right for different values";
    ok !sv_numne($o1, $o2), "sv_numne two overloads";
    ok sv_numne($o1, $o3), "sv_numne two different overloads";
    ok !sv_numne($o1, $big), "sv_numne left overload";
    ok !sv_numne($bigm1, $o3), "sv_numne right overload";
}
