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

print "1..80\n";

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
  my($a,$b);
  { use bytes; $a = "\xc3\xa4"; }  
  { use utf8;  $b = "\xe4"; }
  { use bytes; ok_bytes $a, $b; $test++; } # 69
  { use utf8;  nok      $a, $b; $test++; } # 70
}

{
    my @x = ("stra\337e 138","stra\337e 138");
    for (@x) {
	s/(\d+)\s*([\w\-]+)/$1 . uc $2/e;
	my($latin) = /^(.+)(?:\s+\d)/;
	print $latin eq "stra\337e" ? "ok $test\n" :
	    "#latin[$latin]\nnot ok $test\n";
	$test++;
	$latin =~ s/stra\337e/straße/; # \303\237 after the 2nd a
	use utf8;
	$latin =~ s!(s)tr(?:aß|s+e)!$1tr.!; # \303\237 after the a
    }
}

{
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
