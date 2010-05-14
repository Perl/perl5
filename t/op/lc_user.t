BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 5;

%utf8::ToSpecUpper = (
"s" => "SS",            # Make sure can handle weird ASCII translations
);

sub ToUpper {
    return <<END;
0061	0063	0041
END
}

is("\Ufoo\x{101}", "foo\x{101}", "no changes on 'foo'");
is("\Ubar\x{101}", "BAr\x{101}", "changing 'ab' on 'bar' ");
my $s = 's';
utf8::upgrade $s;
is(uc($s), "SS", "Verify uc('s') is 'SS' with our weird xlation, and utf8");

sub ToLower {
    return <<END;
0041		0061
END
}

is("\LFOO\x{100}", "FOO\x{100}", "no changes on 'FOO'");
is("\LBAR\x{100}", "BaR\x{100}", "changing 'A' on 'BAR' ");

