#!perl

use Test::More tests => 11;
use XS::APItest;

my $four = 4;
ok !sv_numne($four, 4), '$four == 4'; # not(not equal)
ok  sv_numne($four, 5), '$four != 5';

my $six_point_five = 6.5; # an exact float, so == is fine
ok !sv_numne($six_point_five, 6.5), '$six_point_five == 6.5';
ok  sv_numne($six_point_five, 6.6), '$six_point_five != 6.6';

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

    ok !sv_numne_flags($obj, 11, SV_SKIP_OVERLOAD), 'AlwaysTwelve is 12 with SV_SKIP_OVERLOAD'
}

done_testing();
