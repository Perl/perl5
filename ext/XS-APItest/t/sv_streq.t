#!perl

use Test::More tests => 9;
use XS::APItest;

my $abc = "abc";
ok  sv_streq($abc, "abc"), '$abc eq "abc"';
ok !sv_streq($abc, "def"), '$abc ne "def"';

{
    # U+00E9 = LATIN SMALL LETTER E WITH ACUTE
    #  UTF-8: \xc3 \xa9
    my $cafe_LATIN1 = "caf\xe9";
    utf8::upgrade(my $cafe_UNICODE = "caf\x{00e9}");
    utf8::encode (my $cafe_UTF8    = "caf\x{00e9}");

    # Latin-1 and Unicode strings should compare equal despite containing
    # different underlying bytes in the SvPV
    ok sv_streq($cafe_LATIN1, $cafe_UNICODE), 'sv_streq handles UTF8 strings';

    # UTF-8 and Unicode strings should not compare equal, even though they
    # contain the same bytes in the SvPV
    ok !sv_streq($cafe_UTF8, $cafe_UNICODE), 'sv_streq takes UTF8ness into account';
}

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
