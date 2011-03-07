#!./perl -w

BEGIN {
    require './test.pl';
    skip_all_if_miniperl("no dynamic loading on miniperl, no Encode");
    skip_all("EBCDIC") if $::IS_EBCDIC;
    skip_all_without_perlio();
    skip_all_without_extension('Encode');
}

use strict;
plan (tests => 6);
use encoding 'johab';

ok(chr(0x7f) eq "\x7f");
ok(chr(0x80) eq "\x80");
ok(chr(0xff) eq "\xff");

for my $i (127, 128, 255) {
    ok(chr($i) eq pack('C', $i));
}

__END__
