#!perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require "./test.pl";
}

plan(tests => 32);

sub f($$_) { my $x = shift; is("@_", $x) }

$foo = "FOO";
my $bar = "BAR";
$_ = 42;

f("FOO xy", $foo, "xy");
f("BAR zt", $bar, "zt");
f("FOO 42", $foo);
f("BAR 42", $bar);
f("y 42", substr("xy",1,1));
f("1 42", ("abcdef" =~ /abc/));
f("not undef 42", $undef || "not undef");
f(" 42", -f "no_such_file");
f("FOOBAR 42", ($foo . $bar));
f("FOOBAR 42", ($foo .= $bar));
f("FOOBAR 42", $foo);

eval q{ f("foo") };
like( $@, qr/Not enough arguments for main::f at/ );
eval q{ f(1,2,3,4) };
like( $@, qr/Too many arguments for main::f at/ );

{
    my $_ = "quarante-deux";
    $foo = "FOO";
    $bar = "BAR";
    f("FOO quarante-deux", $foo);
    f("BAR quarante-deux", $bar);
    f("y quarante-deux", substr("xy",1,1));
    f("1 quarante-deux", ("abcdef" =~ /abc/));
    f("not undef quarante-deux", $undef || "not undef");
    f(" quarante-deux", -f "no_such_file");
    f("FOOBAR quarante-deux", ($foo . $bar));
    f("FOOBAR quarante-deux", ($foo .= $bar));
    f("FOOBAR quarante-deux", $foo);
}

&f(""); # no error

sub g(_) { is(shift, $expected) }

$expected = "foo";
g("foo");
g($expected);
$_ = $expected;
g();
undef $expected; &g; # $_ not passed
{ $expected = my $_ = "bar"; g() }

eval q{ sub wrong1 (_$); wrong1(1,2) };
like( $@, qr/Malformed prototype for main::wrong1/, 'wrong1' );

eval q{ sub wrong2 ($__); wrong2(1,2) };
like( $@, qr/Malformed prototype for main::wrong2/, 'wrong2' );

sub opt ($;_) { is($_[0], "seen"); ok(!defined $_[1], "; has precedence over _") }
opt("seen");
