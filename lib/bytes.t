BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

plan tests => 9;

my $a = chr(0x100);

is(ord($a), 0x100, "ord sanity check");
is(length($a), 1,  "length sanity check");
is(bytes::length($a), 2,  "bytes::length sanity check");

{
    use bytes;
    my $b = chr(0x100); # affected by 'use bytes'
    is(ord($b), 0, "chr truncates under use bytes");
    is(length($b), 1, "length truncated under use bytes");
    is(bytes::length($b), 1, "bytes::length truncated under use bytes");
}

my $c = chr(0x100);

{
    use bytes;
    if (ord('A') == 193) { # EBCDIC?
	is(ord($c), 0x8c, "ord under use bytes looks at the 1st byte");
    } else {
	is(ord($c), 0xc4, "ord under use bytes looks at the 1st byte");
    }
    is(length($c), 2, "length under use bytes looks at bytes");
    is(bytes::length($c), 2, "bytes::length under use bytes looks at bytes");
}
