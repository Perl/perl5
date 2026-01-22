#!perl

use Test::More tests => 24;
use XS::APItest;
use Config;
use strict;

my $four = 4;
is sv_numcmp($four, 4),  0, '$four == 4';
is sv_numcmp($four, 5), -1, '$four < 5';

is sv_numcmp(5, $four),  1, '5 > $four';

SKIP:
{
    no warnings 'experimental';
    my $nan = eval { builtin::nan };
    defined $nan
      or skip "No NAN", 2;
    is sv_numcmp($nan, 0),    2, '$nan not comparable';
    is sv_numcmp($nan, $nan), 2, '$nan not comparable even with itself';
}

my $six_point_five = 6.5; # an exact float, so == is fine
is sv_numcmp($six_point_five, 6.5),  0, '$six_point_five == 6.5';
is sv_numcmp($six_point_five, 6.6), -1, '$six_point_five < 6.6';

# NULLs
is sv_numcmp(undef, 1), -1, "NULL sv1";
is sv_numcmp(1, undef),  1, "NULL sv2";

# GMAGIC
"10" =~ m/(\d+)/;
is sv_numcmp_flags($1, 10, 0), -1, 'sv_numcmp_flags with no flags does not GETMAGIC';
is sv_numcmp_flags($1, 10, SV_GMAGIC), 0, 'sv_numcmp_flags with SV_GMAGIC does';

# overloading
{
    package AlwaysTen {
        use overload
            '<=>' => sub {
                return $_[2] ? $_[1] <=> 10  : 10 <=> $_[1]
            },
            '0+' => sub { 123456 };
    }
    my $obj = bless([], "AlwaysTen");

    is sv_numcmp($obj, 10),   0, 'AlwaysTen is 10';
    is sv_numcmp($obj, 11),  -1, 'AlwaysTen is not 11';
    is sv_numcmp(10, $obj),   0, 'AlwaysTen is 10 on the right';
    is sv_numcmp(11, $obj),   1, 'AlwaysTen is not 11 on the right';

  SKIP:
    {
        $Config{d_double_has_nan}
          or skip "No NAN", 1;
        my $nan = 0+"NaN";

        is sv_numcmp($obj, $nan), 2, 'AlwaysTen vs $nan is not comparable';
    }

    is sv_numcmp_flags($obj, 10, SV_SKIP_OVERLOAD), 1,
      'AlwaysTen is not 10 with SV_SKIP_OVERLOAD';
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

    is $o1 <=> $o2,     0, "perl op gets it right";
    is $o1 <=> $bigm1,  1, "perl op still gets it right for left overload";
    is $o1 <=> $o3,     1, "perl op still gets it right for different values";
    is sv_numcmp($o1, $o2),    0, "sv_numcmp two overloads";
    is sv_numcmp($o1, $o3),    1, "sv_numcmp two different overloads";
    is sv_numcmp($o1, $big),   0, "sv_numcmp left overload";
    is sv_numcmp($bigm1, $o3), 0, "sv_numcmp right overload";
}
