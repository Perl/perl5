#!./perl

print "1..45\n";

my $test = 1;

sub ok {
    if ($_[0]) {
	if ($_[1]) {
	    print "ok $test - $_[1]\n";
	} else {
	    print "ok $test\n";
	}
    } else {
	if ($_[1]) {
	    print "not ok $test - $_[1]\n";
	} else {
	    print "not ok $test\n";
	}
    }
    $test++;
}

$a = "HELLO.* world";
$b = "hello.* WORLD";

ok("\Q$a\E."      eq "HELLO\\.\\*\\ world.", '\Q\E HELLO.* world');
ok("\u$a"         eq "HELLO\.\* world",      '\u');
ok("\l$a"         eq "hELLO\.\* world",      '\l');
ok("\U$a"         eq "HELLO\.\* WORLD",      '\U');
ok("\L$a"         eq "hello\.\* world",      '\L');

ok(quotemeta($a)  eq "HELLO\\.\\*\\ world",  'quotemeta');
ok(ucfirst($a)    eq "HELLO\.\* world",      'ucfirst');
ok(lcfirst($a)    eq "hELLO\.\* world",      'lcfirst');
ok(uc($a)         eq "HELLO\.\* WORLD",      'uc');
ok(lc($a)         eq "hello\.\* world",      'lc');

ok("\Q$b\E."      eq "hello\\.\\*\\ WORLD.", '\Q\E hello.* WORLD');
ok("\u$b"         eq "Hello\.\* WORLD",      '\u');
ok("\l$b"         eq "hello\.\* WORLD",      '\l');
ok("\U$b"         eq "HELLO\.\* WORLD",      '\U');
ok("\L$b"         eq "hello\.\* world",      '\L');

ok(quotemeta($b)  eq "hello\\.\\*\\ WORLD",  'quotemeta');
ok(ucfirst($b)    eq "Hello\.\* WORLD",      'ucfirst');
ok(lcfirst($b)    eq "hello\.\* WORLD",      'lcfirst');
ok(uc($b)         eq "HELLO\.\* WORLD",      'uc');
ok(lc($b)         eq "hello\.\* world",      'lc');

# \x{100} is LATIN CAPITAL LETTER A WITH MACRON; its bijective lowercase is
# \x{100}, LATIN SMALL LETTER A WITH MACRON.

$a = "\x{100}\x{101}\x{41}\x{61}";
$b = "\x{101}\x{100}\x{61}\x{41}";

ok("\Q$a\E."      eq "\x{100}\x{101}\x{41}\x{61}.", '\Q\E \x{100}\x{101}\x{41}\x{61}');
ok("\u$a"         eq "\x{100}\x{101}\x{41}\x{61}",  '\u');
ok("\l$a"         eq "\x{101}\x{101}\x{41}\x{61}",  '\l');
ok("\U$a"         eq "\x{100}\x{100}\x{41}\x{41}",  '\U');
ok("\L$a"         eq "\x{101}\x{101}\x{61}\x{61}",  '\L');

ok(quotemeta($a)  eq "\x{100}\x{101}\x{41}\x{61}",  'quotemeta');
ok(ucfirst($a)    eq "\x{100}\x{101}\x{41}\x{61}",  'ucfirst');
ok(lcfirst($a)    eq "\x{101}\x{101}\x{41}\x{61}",  'lcfirst');
ok(uc($a)         eq "\x{100}\x{100}\x{41}\x{41}",  'uc');
ok(lc($a)         eq "\x{101}\x{101}\x{61}\x{61}",  'lc');

ok("\Q$b\E."      eq "\x{101}\x{100}\x{61}\x{41}.", '\Q\E \x{101}\x{100}\x{61}\x{41}');
ok("\u$b"         eq "\x{100}\x{100}\x{61}\x{41}",  '\u');
ok("\l$b"         eq "\x{101}\x{100}\x{61}\x{41}",  '\l');
ok("\U$b"         eq "\x{100}\x{100}\x{41}\x{41}",  '\U');
ok("\L$b"         eq "\x{101}\x{101}\x{61}\x{61}",  '\L');

ok(quotemeta($b)  eq "\x{101}\x{100}\x{61}\x{41}",  'quotemeta');
ok(ucfirst($b)    eq "\x{100}\x{100}\x{61}\x{41}",  'ucfirst');
ok(lcfirst($b)    eq "\x{101}\x{100}\x{61}\x{41}",  'lcfirst');
ok(uc($b)         eq "\x{100}\x{100}\x{41}\x{41}",  'uc');
ok(lc($b)         eq "\x{101}\x{101}\x{61}\x{61}",  'lc');

# \x{DF} is LATIN SMALL LETTER SHARP S, its uppercase is SS or \x{53}\x{53};
# \x{149} is LATIN SMALL LETTER N PRECEDED BY APOSTROPHE, its uppercase is
# \x{2BC}\x{E4} or MODIFIER LETTER APOSTROPHE and N.

ok("\U\x{DF}ab\x{149}cd" eq "\x{53}\x{53}AB\x{2BC}\x{4E}CD",
   "multicharacter uppercase");

# The \x{DF} is its own lowercase, ditto for \x{149}.
# There are no single character -> multiple characters lowercase mappings.

ok("\L\x{DF}AB\x{149}CD" eq "\x{DF}ab\x{149}cd",
   "multicharacter lowercase");

# titlecase is used for \u / ucfirst.

# \x{587} is ARMENIAN SMALL LIGATURE ECH YIWN and its titlecase is
# \x{535}\x{582} ARMENIAN CAPITAL LETTER ECH + ARMENIAN SMALL LETTER YIWN
# while its lowercase is 
# \x{587} itself
# and its uppercase is
# \x{535}\x{552} ARMENIAN CAPITAL LETTER ECH + ARMENIAN CAPITAL LETTER YIWN

$a = "\x{587}";

ok("\L\x{587}" eq "\x{587}",        "ligature lowercase");
ok("\u\x{587}" eq "\x{535}\x{582}", "ligature titlecase");
ok("\U\x{587}" eq "\x{535}\x{552}", "ligature uppercase");

