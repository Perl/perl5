# Verifies that can implement Turkish casing as defined by Unicode 5.2.

use Config;

BEGIN {
    chdir 't';
    @INC = '../lib';
    require './test.pl';
}

use subs qw(lc lcfirst uc ucfirst);

sub uc($) {
    my $string = shift;
    utf8::upgrade($string);
    return CORE::uc($string);
}

sub ucfirst($) {
    my $string = shift;
    utf8::upgrade($string);
    return CORE::ucfirst($string);
}

sub lc($) {
    my $string = shift;
    utf8::upgrade($string);

    # Unless an I is before a dot_above, it turns into a dotless i.
    $string =~ s/I (?! [^\p{ccc=0}\p{ccc=Above}]* \x{0307} )/\x{131}/gx;

    # But when the I is followed by a dot_above, remove the dot_above so
    # the end result will be i.
    $string =~ s/I ([^\p{ccc=0}\p{ccc=Above}]* ) \x{0307}/i$1/gx;
    return CORE::lc($string);
}

sub lcfirst($) {
    my $string = shift;
    utf8::upgrade($string);

    # Unless an I is before a dot_above, it turns into a dotless i.
    $string =~ s/^I (?! [^\p{ccc=0}\p{ccc=Above}]* \x{0307} )/\x{131}/x;

    # But when the I is followed by a dot_above, remove the dot_above so
    # the end result will be i.
    $string =~ s/^I ([^\p{ccc=0}\p{ccc=Above}]* ) \x{0307}/i$1/x;
    return CORE::lcfirst($string);
}

plan tests => 22;

my $map_directory = "../lib/unicore/To";
my $upper = "$map_directory/Upper.pl";
my $lower = "$map_directory/Lower.pl";
my $title = "$map_directory/Title.pl";

sub ToUpper {
    my $official = do $upper;
    $utf8::ToSpecUpper{'i'} = "\x{0130}";
    return $official;
}

sub ToTitle {
    my $official = do $title;
    $utf8::ToSpecTitle{'i'} = "\x{0130}";
    return $official;
}

sub ToLower {
    my $official = do $lower;
    $utf8::ToSpecLower{"\xc4\xb0"} = "i";
    return $official;
}

is(uc("\x{DF}\x{DF}"), "SSSS", "Verify that uc of non-overridden multi-char works");
is(uc("aa"), "AA", "Verify that uc of non-overridden ASCII works");
is(uc("\x{101}\x{101}"), "\x{100}\x{100}", "Verify that uc of non-overridden utf8 works");
is(uc("ii"), "\x{130}\x{130}", "Verify uc('ii') eq \\x{130}\\x{130}");

is(ucfirst("\x{DF}\x{DF}"), "Ss\x{DF}", "Verify that ucfirst of non-overridden multi-char works");
is(ucfirst("\x{101}\x{101}"), "\x{100}\x{101}", "Verify that ucfirst of non-overridden utf8 works");
is(ucfirst("aa"), "Aa", "Verify that ucfirst of non-overridden ASCII works");
is(ucfirst("ii"), "\x{130}i", "Verify ucfirst('ii') eq \"\\x{130}i\"");

is(lc("AA"), "aa", "Verify that lc of non-overridden ASCII works");
is(lc("\x{C0}\x{C0}"), "\x{E0}\x{E0}", "Verify that lc of non-overridden latin1 works");
is(lc("\x{0178}\x{0178}"), "\x{FF}\x{FF}", "Verify that lc of non-overridden utf8 works");
is(lc("II"), "\x{131}\x{131}", "Verify that lc('I') eq \\x{131}");
is(lc("IG\x{0307}IG\x{0307}"), "\x{131}g\x{0307}\x{131}g\x{0307}", "Verify that lc(\"I...\\x{0307}\") eq \"\\x{131}...\\x{0307}\"");
is(lc("I\x{0307}I\x{0307}"), "ii", "Verify that lc(\"I\\x{0307}\") removes the \\x{0307}, leaving 'i'");
is(lc("\x{130}\x{130}"), "ii", "Verify that lc(\"\\x{130}\\x{130}\") eq 'ii'");

is(lcfirst("AA"), "aA", "Verify that lcfirst of non-overridden ASCII works");
is(lcfirst("\x{C0}\x{C0}"), "\x{E0}\x{C0}", "Verify that lcfirst of non-overridden latin1 works");
is(lcfirst("\x{0178}\x{0178}"), "\x{FF}\x{0178}", "Verify that lcfirst of non-overridden utf8 works");
is(lcfirst("I"), "\x{131}", "Verify that lcfirst('II') eq \"\\x{131}I\"");
is(lcfirst("IG\x{0307}"), "\x{131}G\x{0307}", "Verify that lcfirst(\"I...\\x{0307}\") eq \"\\x{131}...\\x{0307}\"");
is(lcfirst("I\x{0307}I\x{0307}"), "iI\x{0307}", "Verify that lcfirst(\"I\\x{0307}I\\x{0307}\") removes the first \\x{0307}, leaving 'iI\\x{0307}'");
is(lcfirst("\x{130}\x{130}"), "i\x{130}", "Verify that lcfirst(\"\\x{130}\\x{130}\") eq \"i\\x{130}\"");
