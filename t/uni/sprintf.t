#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    require "./test.pl";
    set_up_inc(qw(../lib .));
}

plan tests => 52;

my ($alpha, $beta, $c);
$alpha = "B\x{fc}f";
$beta = "G\x{100}r";
$c = 0x200;

{
    my $s = sprintf "%s", $alpha;
    is($s, $alpha, "%s a");
}

{
    my $s = sprintf "%s", $beta;
    is($s, $beta, "%s b");
}

{
    my $s = sprintf "%s%s", $alpha, $beta;
    is($s, $alpha.$beta, "%s%s a b");
}

{
    my $s = sprintf "%s%s", $beta, $alpha;
    is($s, $beta.$alpha, "%s%s b a");
}

{
    my $s = sprintf "%s%s", $beta, $beta;
    is($s, $beta.$beta, "%s%s b b");
}

{
    my $s = sprintf "%s$beta", $alpha;
    is($s, $alpha.$beta, "%sb a");
}

{
    my $s = sprintf "$beta%s", $alpha;
    is($s, $beta.$alpha, "b%s a");
}

{
    my $s = sprintf "%s$alpha", $beta;
    is($s, $beta.$alpha, "%sa b");
}

{
    my $s = sprintf "$alpha%s", $beta;
    is($s, $alpha.$beta, "a%s b");
}

{
    my $s = sprintf "$alpha%s", $alpha;
    is($s, $alpha.$alpha, "a%s a");
}

{
    my $s = sprintf "$beta%s", $beta;
    is($s, $beta.$beta, "a%s b");
}

{
    my $s = sprintf "%c", $c;
    is($s, chr($c), "%c c");
}

{
    my $s = sprintf "%s%c", $alpha, $c;
    is($s, $alpha.chr($c), "%s%c a c");
}

{
    my $s = sprintf "%c%s", $c, $alpha;
    is($s, chr($c).$alpha, "%c%s c a");
}

{
    my $s = sprintf "%c$beta", $c;
    is($s, chr($c).$beta, "%cb c");
}

{
    my $s = sprintf "%s%c$beta", $alpha, $c;
    is($s, $alpha.chr($c).$beta, "%s%cb a c");
}

{
    my $s = sprintf "%c%s$beta", $c, $alpha;
    is($s, chr($c).$alpha.$beta, "%c%sb c a");
}

{
    my $s = sprintf "$beta%c", $c;
    is($s, $beta.chr($c), "b%c c");
}

{
    my $s = sprintf "$beta%s%c", $alpha, $c;
    is($s, $beta.$alpha.chr($c), "b%s%c a c");
}

{
    my $s = sprintf "$beta%c%s", $c, $alpha;
    is($s, $beta.chr($c).$alpha, "b%c%s c a");
}

{
    # 20010407.008 (#6769) sprintf removes utf8-ness
    $alpha = sprintf "\x{1234}";
    is((sprintf "%x %d", unpack("U*", $alpha), length($alpha)),    "1234 1",
       '\x{1234}');
    $alpha = sprintf "%s", "\x{5678}";
    is((sprintf "%x %d", unpack("U*", $alpha), length($alpha)),    "5678 1",
       '%s \x{5678}');
    $alpha = sprintf "\x{1234}%s", "\x{5678}";
    is((sprintf "%x %x %d", unpack("U*", $alpha), length($alpha)), "1234 5678 2",
       '\x{1234}%s \x{5678}');
}

{
    # check that utf8ness doesn't "accumulate"

    my $w = "w\x{fc}";
    my $sprintf;

    $sprintf = sprintf "%s%s", $w, "$w\x{100}";
    is(substr($sprintf,0,2), $w, "utf8 echo");

    $sprintf = sprintf "%s%s", $w, "$w\x{100}";    
    is(substr($sprintf,0,2), $w, "utf8 echo echo");
}

my @values =(chr 110, chr 255, chr 256);

foreach my $prefix (@values) {
    foreach my $vector (map {$_ . $_} @values) {

	my $format = "$prefix%*vd";

	foreach my $dot (@values) {
	    my $result = sprintf $format, $dot, $vector;
	    is (length $result, 8)
		or print "# ", join (',', map {ord $_} $prefix, $dot, $vector),
		  "\n";
	}
    }
}
