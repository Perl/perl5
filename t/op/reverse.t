#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 5;

is(reverse("abc"), "cba");

$_ = "foobar";
is(reverse(), "raboof");

{
    my @a = ("foo", "bar");
    my @b = reverse @a;

    is($b[0], $a[1]);
    is($b[1], $a[0]);
}

{
    # Unicode.

    my $a = "\x{263A}\x{263A}x\x{263A}y\x{263A}";
    my $b = scalar reverse($a);
    my $c = scalar reverse($b);
    is($a, $c);
}
