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

print "1..106\n";

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
    # no use utf8 needed
    $_ = "\x{263A}\x{263A}x\x{263A}y\x{263A}";
    
    ok length($_), 6;			# 13
    $test++;

    ($a) = m/x(.)/;

    ok length($a), 1;			# 14
    $test++;

    ok length($`), 2;			# 15
    $test++;
    ok length($&), 2;			# 16
    $test++;
    ok length($'), 2;			# 17
    $test++;

    ok length($1), 1;			# 18
    $test++;

    ok length($b=$`), 2;		# 19
    $test++;

    ok length($b=$&), 2;		# 20
    $test++;

    ok length($b=$'), 2;		# 21
    $test++;

    ok length($b=$1), 1;		# 22
    $test++;

    ok $a, "\x{263A}";			# 23
    $test++;

    ok $`, "\x{263A}\x{263A}";		# 24
    $test++;

    ok $&, "x\x{263A}";			# 25
    $test++;

    ok $', "y\x{263A}";			# 26
    $test++;

    ok $1, "\x{263A}";			# 27
    $test++;

    ok_bytes $a, "\342\230\272";	# 28
    $test++;

    ok_bytes $1, "\342\230\272";	# 29
    $test++;

    ok_bytes $&, "x\342\230\272";	# 30
    $test++;

    {
	use utf8; # required
	$_ = chr(0x263A) . chr(0x263A) . 'x' . chr(0x263A) . 'y' . chr(0x263A);
    }

    ok length($_), 6;			# 31
    $test++;

    ($a) = m/x(.)/;

    ok length($a), 1;			# 32
    $test++;

    ok length($`), 2;			# 33
    $test++;

    ok length($&), 2;			# 34
    $test++;

    ok length($'), 2;			# 35
    $test++;

    ok length($1), 1;			# 36
    $test++;

    ok length($b=$`), 2;		# 37
    $test++;

    ok length($b=$&), 2;		# 38
    $test++;

    ok length($b=$'), 2;		# 39
    $test++;

    ok length($b=$1), 1;		# 40
    $test++;

    ok $a, "\x{263A}";			# 41
    $test++;

    ok $`, "\x{263A}\x{263A}";		# 42
    $test++;

    ok $&, "x\x{263A}";			# 43
    $test++;

    ok $', "y\x{263A}";			# 44
    $test++;

    ok $1, "\x{263A}";			# 45
    $test++;

    ok_bytes $a, "\342\230\272";	# 46
    $test++;

    ok_bytes $1, "\342\230\272";	# 47
    $test++;

    ok_bytes $&, "x\342\230\272";	# 48
    $test++;

    $_ = "\342\230\272\342\230\272x\342\230\272y\342\230\272";

    ok length($_), 14;			# 49
    $test++;

    ($a) = m/x(.)/;

    ok length($a), 1;			# 50
    $test++;

    ok length($`), 6;			# 51
    $test++;

    ok length($&), 2;			# 52
    $test++;

    ok length($'), 6;			# 53
    $test++;

    ok length($1), 1;			# 54
    $test++;

    ok length($b=$`), 6;		# 55
    $test++;

    ok length($b=$&), 2;		# 56
    $test++;

    ok length($b=$'), 6;		# 57
    $test++;

    ok length($b=$1), 1;		# 58
    $test++;

    ok $a, "\342";			# 59
    $test++;

    ok $`, "\342\230\272\342\230\272";	# 60
    $test++;

    ok $&, "x\342";			# 61
    $test++;

    ok $', "\230\272y\342\230\272";	# 62
    $test++;

    ok $1, "\342";			# 63
    $test++;
}

{
    use utf8;
    ok "\x{ab}" =~ /^\x{ab}$/, 1;
    $test++;				# 64
}

{
    use utf8;
    ok_bytes chr(0x1e2), pack("C*", 0xc7, 0xa2);
    $test++;                # 65
}

{
    use utf8;
    my @a = map ord, split(//, join("", map chr, (1234, 123, 2345)));
    ok "@a", "1234 123 2345";
    $test++;                # 66
}

{
    use utf8;
    my $x = chr(123);
    my @a = map ord, split(/$x/, join("", map chr, (1234, 123, 2345)));
    ok "@a", "1234 2345";
    $test++;                # 67
}

{
    # bug id 20001009.001

    my ($a, $b);

    { use bytes; $a = "\xc3\xa4" }
    { use utf8;  $b = "\xe4"     } # \xXX must not produce UTF-8

    print "not " if $a eq $b;
    print "ok $test\n"; $test++;	# 68

    { use utf8; print "not " if $a eq $b; }
    print "ok $test\n"; $test++;	# 69
}

{
    # bug id 20001008.001

    my @x = ("stra\337e 138","stra\337e 138");
    for (@x) {
	s/(\d+)\s*([\w\-]+)/$1 . uc $2/e;
	my($latin) = /^(.+)(?:\s+\d)/;
	print $latin eq "stra\337e" ? "ok $test\n" :	# 70, 71
	    "#latin[$latin]\nnot ok $test\n";
	$test++;
	$latin =~ s/stra\337e/straße/; # \303\237 after the 2nd a
	use utf8;
	$latin =~ s!(s)tr(?:aß|s+e)!$1tr.!; # \303\237 after the a
    }
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
    print "ok $test\n";			# 72
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
    $test++;				# 73

    my ($a, $b) = split(/\x{100}/, $s);
    print "not " unless $a eq "\x20\x40\x{80}" && $b eq "\x{80}\x40\x20";
    print "ok $test\n";
    $test++;				# 74

    my ($a, $b) = split(/\x{80}\x{100}\x{80}/, $s);
    print "not " unless $a eq "\x20\x40" && $b eq "\x40\x20";
    print "ok $test\n";
    $test++;				# 75

    my ($a, $b) = split(/\x40\x{80}/, $s);
    print "not " unless $a eq "\x20" && $b eq "\x{100}\x{80}\x40\x20";
    print "ok $test\n";
    $test++;				# 76

    my ($a, $b, $c) = split(/[\x40\x{80}]+/, $s);
    print "not " unless $a eq "\x20" && $b eq "\x{100}" && $c eq "\x20";
    print "ok $test\n";
    $test++;				# 77
}

{
    # bug id 20000730.004

    use utf8;

    my $smiley = "\x{263a}";

    for my $s ("\x{263a}",                     # 78
	       $smiley,                        # 79
		
	       "" . $smiley,                   # 80
	       "" . "\x{263a}",                # 81

	       $smiley    . "",                # 82
	       "\x{263a}" . "",                # 83
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

    for my $s ("\x{263a}" . "\x{263a}",        # 84
	       $smiley    . $smiley,           # 85

	       "\x{263a}\x{263a}",             # 86
	       "$smiley$smiley",               # 87
	       
	       "\x{263a}" x 2,                 # 88
	       $smiley    x 2,                 # 89
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
    use utf8;

    print "not " unless "ba\xd4c" =~ /([a\xd4]+)/ && $1 eq "a\xd4";
    print "ok $test\n";
    $test++;					# 90

    print "not " unless "ba\xd4c" =~ /([a\xd4]+)/ && $1 eq "a\x{d4}";
    print "ok $test\n";
    $test++;					# 91

    print "not " unless "ba\x{d4}c" =~ /([a\xd4]+)/ && $1 eq "a\x{d4}";
    print "ok $test\n";
    $test++;					# 92

    print "not " unless "ba\x{d4}c" =~ /([a\xd4]+)/ && $1 eq "a\xd4";
    print "ok $test\n";
    $test++;					# 93

    print "not " unless "ba\xd4c" =~ /([a\x{d4}]+)/ && $1 eq "a\xd4";
    print "ok $test\n";
    $test++;					# 94

    print "not " unless "ba\xd4c" =~ /([a\x{d4}]+)/ && $1 eq "a\x{d4}";
    print "ok $test\n";
    $test++;					# 95

    print "not " unless "ba\x{d4}c" =~ /([a\x{d4}]+)/ && $1 eq "a\x{d4}";
    print "ok $test\n";
    $test++;					# 96

    print "not " unless "ba\x{d4}c" =~ /([a\x{d4}]+)/ && $1 eq "a\xd4";
    print "ok $test\n";
    $test++;					# 97
}

{
    # the first half of 20001028.003

    my $X = chr(1448);
    my ($Y) = $X =~ /(.*)/;
    print "not " unless $Y eq v1448 && length($Y) == 1;
    print "ok $test\n";
    $test++;					# 98
}

{
    # 20001108.001

    use utf8;
    my $X = "Szab\x{f3},Bal\x{e1}zs";
    my $Y = $X;
    $Y =~ s/(B)/$1/ for 0..3;
    print "not " unless $Y eq $X && $X eq "Szab\x{f3},Bal\x{e1}zs";
    print "ok $test\n";
    $test++;					# 99
}

{
    # 20001114.001	

    use utf8;
    use charnames ':full';
    my $text = "\N{LATIN CAPITAL LETTER A WITH DIAERESIS}";
    print "not " unless $text eq "\xc4" && ord($text) == 0xc4;
    print "ok $test\n";
    $test++;                                    # 100
}

{
    # 20001205.014

    use utf8;

    my $a = "ABC\x{263A}";

    my @b = split( //, $a );

    print "not " unless @b == 4;
    print "ok $test\n";
    $test++;                                    # 101

    print "not " unless length($b[3]) == 1 && $b[3] eq "\x{263A}";
    print "ok $test\n";
    $test++;                                    # 102

    $a =~ s/^A/Z/;
    print "not " unless length($a) == 4 && $a eq "ZBC\x{263A}";
    print "ok $test\n";
    $test++;                                    # 103
}

{
    # the second half of 20001028.003

    use utf8;
    $X =~ s/^/chr(1488)/e;
    print "not " unless length $X == 1 && ord($X) == 1488;
    print "ok $test\n";
    $test++;					# 104
}

{
    # 20000517.001

    my $x = "\x{100}A";

    $x =~ s/A/B/;

    print "not " unless $x eq "\x{100}B" && length($x) == 2;
    print "ok $test\n";
    $test++;					# 105
}

{
    use utf8;

    my @a = split(/\xFE/, "\xFF\xFE\xFD");

    print "not " unless @a == 2 && $a[0] eq "\xFF" && $a[1] eq "\xFD";
    print "ok $test\n";
    $test++;					# 106
}
