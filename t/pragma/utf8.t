#!./perl 

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    $ENV{PERL5LIB} = '../lib';
    if ( ord("\t") != 9 ) { # skip on ebcdic platforms
        print "1..0 # Skip utf8 tests on ebcdic platform.\n";
        exit;
    }
}

print "1..191\n";

my $test = 1;

sub ok {
    my ($got,$expect) = @_;
    print "# expected [$expect], got [$got]\nnot " if $got ne $expect;
    print "ok $test\n";
}

sub nok {
    my ($got,$expect) = @_;
    print "# expected not [$expect], got [$got]\nnot " if $got eq $expect;
    print "ok $test\n";
}

sub ok_bytes {
    use bytes;
    my ($got,$expect) = @_;
    print "# expected [$expect], got [$got]\nnot " if $got ne $expect;
    print "ok $test\n";
}

sub nok_bytes {
    use bytes;
    my ($got,$expect) = @_;
    print "# expected not [$expect], got [$got]\nnot " if $got eq $expect;
    print "ok $test\n";
}

{
    use utf8;
    $_ = ">\x{263A}<"; 
    s/([\x{80}-\x{10ffff}])/"&#".ord($1).";"/eg; 
    ok $_, '>&#9786;<';
    $test++;				# 1

    $_ = ">\x{263A}<"; 
    my $rx = "\x{80}-\x{10ffff}";
    s/([$rx])/"&#".ord($1).";"/eg; 
    ok $_, '>&#9786;<';
    $test++;				# 2

    $_ = ">\x{263A}<"; 
    my $rx = "\\x{80}-\\x{10ffff}";
    s/([$rx])/"&#".ord($1).";"/eg; 
    ok $_, '>&#9786;<';
    $test++;				# 3

    $_ = "alpha,numeric"; 
    m/([[:alpha:]]+)/; 
    ok $1, 'alpha';
    $test++;				# 4

    $_ = "alphaNUMERICstring";
    m/([[:^lower:]]+)/; 
    ok $1, 'NUMERIC';
    $test++;				# 5

    $_ = "alphaNUMERICstring";
    m/(\p{Ll}+)/; 
    ok $1, 'alpha';
    $test++;				# 6

    $_ = "alphaNUMERICstring"; 
    m/(\p{Lu}+)/; 
    ok $1, 'NUMERIC';
    $test++;				# 7

    $_ = "alpha,numeric"; 
    m/([\p{IsAlpha}]+)/; 
    ok $1, 'alpha';
    $test++;				# 8

    $_ = "alphaNUMERICstring";
    m/([^\p{IsLower}]+)/; 
    ok $1, 'NUMERIC';
    $test++;				# 9

    $_ = "alpha123numeric456"; 
    m/([\p{IsDigit}]+)/; 
    ok $1, '123';
    $test++;				# 10

    $_ = "alpha123numeric456"; 
    m/([^\p{IsDigit}]+)/; 
    ok $1, 'alpha';
    $test++;				# 11

    $_ = ",123alpha,456numeric"; 
    m/([\p{IsAlnum}]+)/; 
    ok $1, '123alpha';
    $test++;				# 12
}
{
    use utf8;

    $_ = "\x{263A}>\x{263A}\x{263A}"; 

    ok length, 4;
    $test++;				# 13

    ok length((m/>(.)/)[0]), 1;
    $test++;				# 14

    ok length($&), 2;
    $test++;				# 15

    ok length($'), 1;
    $test++;				# 16

    ok length($`), 1;
    $test++;				# 17

    ok length($1), 1;
    $test++;				# 18

    ok length($tmp=$&), 2;
    $test++;				# 19

    ok length($tmp=$'), 1;
    $test++;				# 20

    ok length($tmp=$`), 1;
    $test++;				# 21

    ok length($tmp=$1), 1;
    $test++;				# 22

    {
	use bytes;

	my $tmp = $&;
	ok $tmp, pack("C*", ord(">"), 0342, 0230, 0272);
	$test++;				# 23

	$tmp = $';
	ok $tmp, pack("C*", 0342, 0230, 0272);
	$test++;				# 24

	$tmp = $`;
	ok $tmp, pack("C*", 0342, 0230, 0272);
	$test++;				# 25

	$tmp = $1;
	ok $tmp, pack("C*", 0342, 0230, 0272);
	$test++;				# 26
    }

    ok_bytes $&, pack("C*", ord(">"), 0342, 0230, 0272);
    $test++;				# 27

    ok_bytes $', pack("C*", 0342, 0230, 0272);
    $test++;				# 28

    ok_bytes $`, pack("C*", 0342, 0230, 0272);
    $test++;				# 29

    ok_bytes $1, pack("C*", 0342, 0230, 0272);
    $test++;				# 30

    {
	use bytes;
	no utf8;

	ok length, 10;
	$test++;				# 31

    	ok length((m/>(.)/)[0]), 1;
    	$test++;				# 32

    	ok length($&), 2;
    	$test++;				# 33

    	ok length($'), 5;
    	$test++;				# 34

    	ok length($`), 3;
    	$test++;				# 35

    	ok length($1), 1;
    	$test++;				# 36

	ok $&, pack("C*", ord(">"), 0342);
	$test++;				# 37

	ok $', pack("C*", 0230, 0272, 0342, 0230, 0272);
	$test++;				# 38

	ok $`, pack("C*", 0342, 0230, 0272);
	$test++;				# 39

	ok $1, pack("C*", 0342);
	$test++;				# 40

    }


    {
	no utf8;
	$_="\342\230\272>\342\230\272\342\230\272";
    }

    ok length, 10;
    $test++;				# 41

    ok length((m/>(.)/)[0]), 1;
    $test++;				# 42

    ok length($&), 2;
    $test++;				# 43

    ok length($'), 1;
    $test++;				# 44

    ok length($`), 1;
    $test++;				# 45

    ok length($1), 1;
    $test++;				# 46

    ok length($tmp=$&), 2;
    $test++;				# 47

    ok length($tmp=$'), 1;
    $test++;				# 48

    ok length($tmp=$`), 1;
    $test++;				# 49

    ok length($tmp=$1), 1;
    $test++;				# 50

    {
	use bytes;

        my $tmp = $&;
	ok $tmp, pack("C*", ord(">"), 0342, 0230, 0272);
	$test++;				# 51

        $tmp = $';
	ok $tmp, pack("C*", 0342, 0230, 0272);
	$test++;				# 52

        $tmp = $`;
	ok $tmp, pack("C*", 0342, 0230, 0272);
	$test++;				# 53

        $tmp = $1;
	ok $tmp, pack("C*", 0342, 0230, 0272);
	$test++;				# 54
    }
    {
	use bytes;
	no utf8;

	ok length, 10;
	$test++;				# 55

    	ok length((m/>(.)/)[0]), 1;
    	$test++;				# 56

    	ok length($&), 2;
    	$test++;				# 57

    	ok length($'), 5;
    	$test++;				# 58

    	ok length($`), 3;
    	$test++;				# 59

    	ok length($1), 1;
    	$test++;				# 60

	ok $&, pack("C*", ord(">"), 0342);
	$test++;				# 61

	ok $', pack("C*", 0230, 0272, 0342, 0230, 0272);
	$test++;				# 62

	ok $`, pack("C*", 0342, 0230, 0272);
	$test++;				# 63

	ok $1, pack("C*", 0342);
	$test++;				# 64

    }

    ok "\x{ab}" =~ /^\x{ab}$/, 1;
    $test++;					# 65
}

{
    use utf8;
    ok_bytes chr(0xe2), pack("C*", 0xc3, 0xa2);
    $test++;                # 66
}

{
    use utf8;
    my @a = map ord, split(//, join("", map chr, (1234, 123, 2345)));
    ok "@a", "1234 123 2345";
    $test++;                # 67
}

{
    use utf8;
    my $x = chr(123);
    my @a = map ord, split(/$x/, join("", map chr, (1234, 123, 2345)));
    ok "@a", "1234 2345";
    $test++;                # 68
}

{
    # bug id 20001009.001

    my ($a, $b);

    { use bytes; $a = "\xc3\xa4" }
    { use utf8;  $b = "\xe4"     } # \xXX must not produce UTF-8

    print "not " if $a eq $b;
    print "ok $test\n"; $test++;

    { use utf8; print "not " if $a eq $b; }
    print "ok $test\n"; $test++;
}

{
    # bug id 20001008.001

    my @x = ("stra\337e 138","stra\337e 138");
    for (@x) {
	s/(\d+)\s*([\w\-]+)/$1 . uc $2/e;
	my($latin) = /^(.+)(?:\s+\d)/;
	print $latin eq "stra\337e" ? "ok $test\n" :
	    "#latin[$latin]\nnot ok $test\n";
	$test++;
	$latin =~ s/stra\337e/stra√üe/; # \303\237 after the 2nd a
	use utf8;
	$latin =~ s!(s)tr(?:a√ü|s+e)!$1tr.!; # \303\237 after the a
    }
}

{
    # bug id 20000819.004 

    $_ = $dx = "\x{10f2}";
    s/($dx)/$dx$1/;
    {
	use bytes;
	print "not " unless $_ eq "$dx$dx";
	print "ok $test\n";
	$test++;
    }

    $_ = $dx = "\x{10f2}";
    s/($dx)/$1$dx/;
    {
	use bytes;
	print "not " unless $_ eq "$dx$dx";
	print "ok $test\n";
	$test++;
    }

    $dx = "\x{10f2}";
    $_  = "\x{10f2}\x{10f2}";
    s/($dx)($dx)/$1$2/;
    {
	use bytes;
	print "not " unless $_ eq "$dx$dx";
	print "ok $test\n";
	$test++;
    }
}

{
    # bug id 20000323.056

    use utf8;

    print "not " unless "\x{41}" eq +v65;
    print "ok $test\n";
    $test++;

    print "not " unless "\x41" eq +v65;
    print "ok $test\n";
    $test++;

    print "not " unless "\x{c8}" eq +v200;
    print "ok $test\n";
    $test++;

    print "not " unless "\xc8" eq +v200;
    print "ok $test\n";
    $test++;

    print "not " unless "\x{221b}" eq v8731;
    print "ok $test\n";
    $test++;
}

{
    # bug id 20000427.003 

    use utf8;
    use warnings;
    use strict;

    my $sushi = "\x{b36c}\x{5a8c}\x{ff5b}\x{5079}\x{505b}";

    my @charlist = split //, $sushi;
    my $r = '';
    foreach my $ch (@charlist) {
	$r = $r . " " . sprintf "U+%04X", ord($ch);
    }

    print "not " unless $r eq " U+B36C U+5A8C U+FF5B U+5079 U+505B";
    print "ok $test\n";
    $test++;
}

{
    # bug id 20000901.092
    # test that undef left and right of utf8 results in a valid string

    my $a;
    $a .= "\x{1ff}";
    print "not " unless $a eq "\x{1ff}";
    print "ok $test\n";
    $test++;
}

{
    # bug id 20000426.003

    use utf8;

    my $s = "\x20\x40\x{80}\x{100}\x{80}\x40\x20";

    my ($a, $b, $c) = split(/\x40/, $s);
    print "not "
	unless $a eq "\x20" && $b eq "\x{80}\x{100}\x{80}" && $c eq $a;
    print "ok $test\n";
    $test++;

    my ($a, $b) = split(/\x{100}/, $s);
    print "not " unless $a eq "\x20\x40\x{80}" && $b eq "\x{80}\x40\x20";
    print "ok $test\n";
    $test++;

    my ($a, $b) = split(/\x{80}\x{100}\x{80}/, $s);
    print "not " unless $a eq "\x20\x40" && $b eq "\x40\x20";
    print "ok $test\n";
    $test++;

    my ($a, $b) = split(/\x40\x{80}/, $s);
    print "not " unless $a eq "\x20" && $b eq "\x{100}\x{80}\x40\x20";
    print "ok $test\n";
    $test++;

    my ($a, $b, $c) = split(/[\x40\x{80}]+/, $s);
    print "not " unless $a eq "\x20" && $b eq "\x{100}" && $c eq "\x20";
    print "ok $test\n";
    $test++;
}

{
    # bug id 20000730.004

    use utf8;

    my $smiley = "\x{263a}";

    for my $s ("\x{263a}",                     #  1
	       $smiley,                        #  2
		
	       "" . $smiley,                   #  3
	       "" . "\x{263a}",                #  4

	       $smiley    . "",                #  5
	       "\x{263a}" . "",                #  6
	       ) {
	my $length_chars = length($s);
	my $length_bytes;
	{ use bytes; $length_bytes = length($s) }
	my @regex_chars = $s =~ m/(.)/g;
	my $regex_chars = @regex_chars;
	my @split_chars = split //, $s;
	my $split_chars = @split_chars;
	print "not "
	    unless "$length_chars/$regex_chars/$split_chars/$length_bytes" eq
		   "1/1/1/3";
	print "ok $test\n";
	$test++;
    }

    for my $s ("\x{263a}" . "\x{263a}",        #  7
	       $smiley    . $smiley,           #  8

	       "\x{263a}\x{263a}",             #  9
	       "$smiley$smiley",               # 10
	       
	       "\x{263a}" x 2,                 # 11
	       $smiley    x 2,                 # 12
	       ) {
	my $length_chars = length($s);
	my $length_bytes;
	{ use bytes; $length_bytes = length($s) }
	my @regex_chars = $s =~ m/(.)/g;
	my $regex_chars = @regex_chars;
	my @split_chars = split //, $s;
	my $split_chars = @split_chars;
	print "not "
	    unless "$length_chars/$regex_chars/$split_chars/$length_bytes" eq
		   "2/2/2/6";
	print "ok $test\n";
	$test++;
    }
}

{
    # ID 20001020.006

    "x" =~ /(.)/; # unset $2

    # Without the fix this will croak:
    # Modification of a read-only value attempted at ...
    "$2\x{1234}";

    print "ok $test\n";
    $test++;

    # For symmetry with the above.
    "\x{1234}$2";

    print "ok $test\n";
    $test++;

    *pi = \undef;
    # This bug existed earlier than the $2 bug, but is fixed with the same
    # patch. Without the fix this will also croak:
    # Modification of a read-only value attempted at ...
    "$pi\x{1234}";

    print "ok $test\n";
    $test++;

    # For symmetry with the above.
    "\x{1234}$pi";

    print "ok $test\n";
    $test++;
}

# This table is based on Markus Kuhn's UTF-8 Decode Stress Tester,
# http://www.cl.cam.ac.uk/~mgk25/ucs/examples/UTF-8-test.txt,
# version dated 2000-09-02. 

my @MK = split(/\n/, <<__EOMK__);
1	Correct UTF-8
1.1.1 y "Œ∫·ΩπœÉŒºŒµ"	-		11	ce:ba:e1:bd:b9:cf:83:ce:bc:ce:b5	5
2	Boundary conditions 
2.1	First possible sequence of certain length
2.1.1 y " "			0		1	00	1
2.1.2 y "¬Ä"			80		2	c2:80	1
2.1.3 y "‡†Ä"		800		3	e0:a0:80	1
2.1.4 y "êÄÄ"		10000		4	f0:90:80:80	1
2.1.5 y "¯àÄÄÄ"	200000		5	f8:88:80:80:80	1
2.1.6 y "¸ÑÄÄÄÄ"	4000000		6	fc:84:80:80:80:80	1
2.2	Last possible sequence of certain length
2.2.1 y ""			7f		1	7f	1
2.2.2 y "ﬂø"			7ff		2	df:bf	1
# The ffff is illegal unless UTF8_ALLOW_FFFF
2.2.3 n "Ôøø"			ffff		3	ef:bf:bf	1
2.2.4 y "˜øøø"			1fffff		4	f7:bf:bf:bf	1
2.2.5 y "˚øøøø"			3ffffff		5	fb:bf:bf:bf:bf	1
2.2.6 y "˝øøøøø"		7fffffff	6	fd:bf:bf:bf:bf:bf	1
2.3	Other boundary conditions
2.3.1 y "Ìüø"		d7ff		3	ed:9f:bf	1
2.3.2 y "ÓÄÄ"		e000		3	ee:80:80	1
2.3.3 y "ÔøΩ"			fffd		3	ef:bf:bd	1
2.3.4 y "Ùèøø"		10ffff		4	f4:8f:bf:bf	1
2.3.5 y "ÙêÄÄ"		110000		4	f4:90:80:80	1
3	Malformed sequences
3.1	Unexpected continuation bytes
3.1.1 n "Ä"			-		1	80
3.1.2 n "ø"			-		1	bf
3.1.3 n "Äø"			-		2	80:bf
3.1.4 n "ÄøÄ"		-		3	80:bf:80
3.1.5 n "ÄøÄø"		-		4	80:bf:80:bf
3.1.6 n "ÄøÄøÄ"	-		5	80:bf:80:bf:80
3.1.7 n "ÄøÄøÄø"	-		6	80:bf:80:bf:80:bf
3.1.8 n "ÄøÄøÄøÄ"	-		7	80:bf:80:bf:80:bf:80
3.1.9 n "ÄÅÇÉÑÖÜáàâäãåçéèêëíìîïñóòôöõúùûü†°¢£§•¶ß®©™´¨≠ÆØ∞±≤≥¥µ∂∑∏π∫ªºΩæø"				-	64	80:81:82:83:84:85:86:87:88:89:8a:8b:8c:8d:8e:8f:90:91:92:93:94:95:96:97:98:99:9a:9b:9c:9d:9e:9f:a0:a1:a2:a3:a4:a5:a6:a7:a8:a9:aa:ab:ac:ad:ae:af:b0:b1:b2:b3:b4:b5:b6:b7:b8:b9:ba:bb:bc:bd:be:bf
3.2	Lonely start characters
3.2.1 n "¿ ¡ ¬ √ ƒ ≈ ∆ « » …   À Ã Õ Œ œ – — “ ” ‘ ’ ÷ ◊ ÿ Ÿ ⁄ € ‹ › ﬁ ﬂ "	-	64 	c0:20:c1:20:c2:20:c3:20:c4:20:c5:20:c6:20:c7:20:c8:20:c9:20:ca:20:cb:20:cc:20:cd:20:ce:20:cf:20:d0:20:d1:20:d2:20:d3:20:d4:20:d5:20:d6:20:d7:20:d8:20:d9:20:da:20:db:20:dc:20:dd:20:de:20:df:20
3.2.2 n "‡ · ‚ „ ‰ Â Ê Á Ë È Í Î Ï Ì Ó Ô "	-	32	e0:20:e1:20:e2:20:e3:20:e4:20:e5:20:e6:20:e7:20:e8:20:e9:20:ea:20:eb:20:ec:20:ed:20:ee:20:ef:20
3.2.3 n " Ò Ú Û Ù ı ˆ ˜ "	-	16	f0:20:f1:20:f2:20:f3:20:f4:20:f5:20:f6:20:f7:20
3.2.4 n "¯ ˘ ˙ ˚ "		-	8	f8:20:f9:20:fa:20:fb:20
3.2.5 n "¸ ˝ "			-	4	fc:20:fd:20
3.3	Sequences with last continuation byte missing
3.3.1 n "¿"			-	1	c0
3.3.2 n "‡Ä"			-	2	e0:80
3.3.3 n "ÄÄ"		-	3	f0:80:80
3.3.4 n "¯ÄÄÄ"		-	4	f8:80:80:80
3.3.5 n "¸ÄÄÄÄ"	-	5	fc:80:80:80:80
3.3.6 n "ﬂ"			-	1	df
3.3.7 n "Ôø"			-	2	ef:bf
3.3.8 n "˜øø"			-	3	f7:bf:bf
3.3.9 n "˚øøø"			-	4	fb:bf:bf:bf
3.3.10 n "˝øøøø"		-	5	fd:bf:bf:bf:bf
3.4	Concatenation of incomplete sequences
3.4.1 n "¿‡ÄÄÄ¯ÄÄÄ¸ÄÄÄÄﬂÔø˜øø˚øøø˝øøøø"	-	30	c0:e0:80:f0:80:80:f8:80:80:80:fc:80:80:80:80:df:ef:bf:f7:bf:bf:fb:bf:bf:bf:fd:bf:bf:bf:bf
3.5	Impossible bytes
3.5.1 n "˛"			-	1	fe
3.5.2 n "ˇ"			-	1	ff
3.5.3 n "˛˛ˇˇ"			-	4	fe:fe:ff:ff
4	Overlong sequences
4.1	Examples of an overlong ASCII character
4.1.1 n "¿Ø"			-	2	c0:af
4.1.2 n "‡ÄØ"		-	3	e0:80:af
4.1.3 n "ÄÄØ"		-	4	f0:80:80:af
4.1.4 n "¯ÄÄÄØ"	-	5	f8:80:80:80:af
4.1.5 n "¸ÄÄÄÄØ"	-	6	fc:80:80:80:80:af
4.2	Maximum overlong sequences
4.2.1 n "¡ø"			-	2	c1:bf
4.2.2 n "‡üø"		-	3	e0:9f:bf
4.2.3 n "èøø"		-	4	f0:8f:bf:bf
4.2.4 n "¯áøøø"		-	5	f8:87:bf:bf:bf
4.2.5 n "¸Éøøøø"		-	6	fc:83:bf:bf:bf:bf
4.3	Overlong representation of the NUL character
4.3.1 n "¿Ä"			-	2	c0:80
4.3.2 n "‡ÄÄ"		-	3	e0:80:80
4.3.3 n "ÄÄÄ"		-	4	f0:80:80:80
4.3.4 n "¯ÄÄÄÄ"	-	5	f8:80:80:80:80
4.3.5 n "¸ÄÄÄÄÄ"	-	6	fc:80:80:80:80:80
5	Illegal code positions
5.1	Single UTF-16 surrogates
5.1.1 n "Ì†Ä"		-	3	ed:a0:80
5.1.2 n "Ì≠ø"			-	3	ed:ad:bf
5.1.3 n "ÌÆÄ"		-	3	ed:ae:80
5.1.4 n "ÌØø"			-	3	ed:af:bf
5.1.5 n "Ì∞Ä"		-	3	ed:b0:80
5.1.6 n "ÌæÄ"		-	3	ed:be:80
5.1.7 n "Ìøø"			-	3	ed:bf:bf
5.2	Paired UTF-16 surrogates
5.2.1 n "Ì†ÄÌ∞Ä"		-	6	ed:a0:80:ed:b0:80
5.2.2 n "Ì†ÄÌøø"		-	6	ed:a0:80:ed:bf:bf
5.2.3 n "Ì≠øÌ∞Ä"		-	6	ed:ad:bf:ed:b0:80
5.2.4 n "Ì≠øÌøø"		-	6	ed:ad:bf:ed:bf:bf
5.2.5 n "ÌÆÄÌ∞Ä"		-	6	ed:ae:80:ed:b0:80
5.2.6 n "ÌÆÄÌøø"		-	6	ed:ae:80:ed:bf:bf
5.2.7 n "ÌØøÌ∞Ä"		-	6	ed:af:bf:ed:b0:80
5.2.8 n "ÌØøÌøø"		-	6	ed:af:bf:ed:bf:bf
5.3	Other illegal code positions
5.3.1 n "Ôøæ"			-	3	ef:bf:be
# The ffff is illegal unless UTF8_ALLOW_FFFF
5.3.2 n "Ôøø"			-	3	ef:bf:bf
__EOMK__

# 104..181
{
    my $WARN;
    my $id;

    local $SIG{__WARN__} =
	sub {
	    # print "# $id: @_";
	    $WARN++;
	};

    sub moan {
	print "$id: @_";
    }
    
    sub test_unpack_U {
	$WARN = 0;
	unpack('U*', $_[0]);
    }

    for (@MK) {
	if (/^(?:\d+(?:\.\d+)?)\s/ || /^#/) {
	    # print "# $_\n";
	} elsif (/^(\d+\.\d+\.\d+[bu]?)\s+([yn])\s+"(.+)"\s+([0-9a-f]{1,8}|-)\s+(\d+)\s+([0-9a-f]{2}(?::[0-9a-f]{2})*)(?:\s+(\d+))?$/) {
	    $id = $1;
	    my ($okay, $bytes, $Unicode, $byteslen, $hex, $charslen) =
		($2, $3, $4, $5, $6, $7);
	    my @hex = split(/:/, $hex);
	    unless (@hex == $byteslen) {
		my $nhex = @hex;
		moan "amount of hex ($nhex) not equal to byteslen ($byteslen)\n";
	    }
	    {
		use bytes;
		my $bytesbyteslen = length($bytes);
		unless ($bytesbyteslen == $byteslen) {
		    moan "bytes length() ($bytesbyteslen) not equal to $byteslen\n";
		}
	    }
	    if ($okay eq 'y') {
		test_unpack_U($bytes);
		unless ($WARN == 0) {
		    moan "unpack('U*') false negative\n";
		    print "not ";
		}
	    } elsif ($okay eq 'n') {
		test_unpack_U($bytes);
		unless ($WARN) {
		    moan "unpack('U*') false positive\n";
		    print "not ";
		}
	    }
	    print "ok $test\n";
	    $test++;
 	} else {
	    moan "unknown format\n";
	}
    }
}

{
    # tests 182..191

    {
	my $a = "\x{41}";

	print "not " unless length($a) == 1;
	print "ok $test\n";
	$test++;

	use bytes;
	print "not " unless $a eq "\x41" && length($a) == 1;
	print "ok $test\n";
	$test++;
    }

    {
	my $a = "\x{80}";

	print "not " unless length($a) == 1;
	print "ok $test\n";
	$test++;

	use bytes;
	print "not " unless $a eq "\xc2\x80" && length($a) == 2;
	print "ok $test\n";
	$test++;
    }

    {
	my $a = "\x{100}";

	print "not " unless length($a) == 1;
	print "ok $test\n";
	$test++;

	use bytes;
	print "not " unless $a eq "\xc4\x80" && length($a) == 2;
	print "ok $test\n";
	$test++;
    }

    {
	my $a = "\x{100}\x{80}";

	print "not " unless length($a) == 2;
	print "ok $test\n";
	$test++;

	use bytes;
	print "not " unless $a eq "\xc4\x80\xc2\x80" && length($a) == 4;
	print "ok $test\n";
	$test++;
    }

    {
	my $a = "\x{80}\x{100}";

	print "not " unless length($a) == 2;
	print "ok $test\n";
	$test++;

	use bytes;
	print "not " unless $a eq "\xc2\x80\xc4\x80" && length($a) == 4;
	print "ok $test\n";
	$test++;
    }
}

