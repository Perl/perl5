#!perl

use Test::More tests => 7;
use XS::APItest;

my $abc = "abc";
ok  sv_streq($abc, "abc"), '$abc eq "abc"';
ok !sv_streq($abc, "def"), '$abc ne "def"';

# consider also UTF-8 vs not

# GMAGIC
"ABC" =~ m/(\w+)/;
ok !sv_streq_flags($1, "ABC", 0), 'sv_streq_flags with no flags does not GETMAGIC';
ok  sv_streq_flags($1, "ABC", SV_GMAGIC), 'sv_streq_flags with SV_GMAGIC does';

# overloading
{
    package AlwaysABC {
        use overload
            'eq' => sub { return $_[1] eq "ABC" },
            '""' => sub { "not-a-string" };
    }
    my $obj = bless([], "AlwaysABC");

    ok  sv_streq($obj, "ABC"), 'AlwaysABC is "ABC"';
    ok !sv_streq($obj, "DEF"), 'AlwaysABC is not "DEF"';

    ok !sv_streq_flags($obj, "ABC", SV_SKIP_OVERLOAD), 'AlwaysABC is not "ABC" with SV_SKIP_OVERLOAD';
}
