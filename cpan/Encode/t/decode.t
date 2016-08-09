#
# $Id: decode.t,v 1.2 2016/08/04 03:15:58 dankogai Exp dankogai $
#
use strict;
use Encode qw(decode_utf8 FB_CROAK find_encoding decode);
use Test::More tests => 5;

sub croak_ok(&) {
    my $code = shift;
    eval { $code->() };
    like $@, qr/does not map/;
}

my $bytes = "L\x{e9}on";
my $pad = "\x{30C9}";

my $orig = $bytes;
croak_ok { Encode::decode_utf8($orig, FB_CROAK) };

my $orig2 = $bytes;
croak_ok { Encode::decode('utf-8', $orig2, FB_CROAK) };

chop(my $new = $bytes . $pad);
croak_ok { Encode::decode_utf8($new, FB_CROAK) };

my $latin1 = find_encoding('latin1');
$orig = "\N{U+0080}";
$orig =~ /(.)/;
is($latin1->decode($1), $orig, '[cpan #115168] passing magic regex globals to decode');
SKIP: {
    skip "Perl Version ($]) is older than v5.16", 1 if $] < 5.016;
    *a = $orig;
    is($latin1->decode(*a), '*main::'.$orig, '[cpan #115168] passing typeglobs to decode');
}
