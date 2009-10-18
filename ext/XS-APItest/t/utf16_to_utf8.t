#!perl -w

use strict;
use Test::More 'no_plan';
use Encode;

use XS::APItest qw(utf16_to_utf8 utf16_to_utf8_reversed);

for my $ord (0, 10, 13, 78, 255, 256, 0xD7FF, 0xE000, 0x10000) {
    my $chr = chr $ord;
    for my $prefix ('', "\0", 'Perl rules') {
	for my $suffix ('', "\0", "Moo!") {
	    my $string = $prefix . $chr . $suffix;
	    my $name = sprintf "for chr $ord prefix %d, suffix %d",
		length $prefix, length $suffix;
	    my $as_utf8 = encode('UTF-8', $string);
	    is(utf16_to_utf8(encode('UTF-16BE', $string)), $as_utf8,
	       "utf16_to_utf8 $name");
	    is(utf16_to_utf8_reversed(encode('UTF-16LE', $string)), $as_utf8,
	       "utf16_to_utf8_reversed $name");
	}
    }
}

# Currently this is special-cased to work. Should it?

is(utf16_to_utf8("\0"), "\0", 'Short string to utf16_to_utf8');

# But anything else is fatal

my $got = eval {utf16_to_utf8('N')};
like($@, qr/^panic: utf16_to_utf8: odd bytelen 1 at/, 'Odd byte length panics');
is($got, undef, 'hence eval returns undef');

for (["\xD8\0\0\0", 'NULs'],
     ["\xD8\0\xD8\0", '2 Lows'],
    ) {
    my ($malformed, $name) = @$_;
    $got = eval {utf16_to_utf8($malformed)};
    like($@, qr/^Malformed UTF-16 surrogate at/,
	 "Malformed surrogate $name croaks for utf16_to_utf8");
    is($got, undef, 'hence eval returns undef');

    $malformed =~ s/(.)(.)/$2$1/gs;
    $got = eval {utf16_to_utf8_reversed($malformed)};
    like($@, qr/^Malformed UTF-16 surrogate at/,
	 "Malformed surrogate $name croaks for utf16_to_utf8_reversed");
    is($got, undef, 'hence eval returns undef');
}

my $in = "NA";
$got = eval {utf16_to_utf8_reversed($in, 1)};
like($@, qr/^panic: utf16_to_utf8_reversed: odd bytelen 1 at/,
     'Odd byte length panics');
is($got, undef, 'hence eval returns undef');
is($in, "NA", 'and input unchanged');

$in = "\xD8\0\xDC\0";
$got = eval {utf16_to_utf8($in, 2)};
like($@, qr/^Malformed UTF-16 surrogate at/, 'Lone surrogate croaks');
(ok(!defined $got, 'hence eval returns undef')) or
    diag(join ', ', map {ord $_} split //, $got);

