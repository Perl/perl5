#!perl -w

use strict;
use HTML::Parser;
use Test::More tests => 103;

SKIP: {
skip "This perl does not support Unicode", 103 if $] < 5.008;

my @warn;
$SIG{__WARN__} = sub {
    push(@warn, $_[0]);
};

my @parsed;
my $p = HTML::Parser->new(
  api_version => 3,
  default_h => [\@parsed, 'event, text, dtext, offset, length, offset_end, column, tokenpos, attr'],
);

my $doc = "<title>\x{263A}</title><h1 id=\x{2600} f>Smile &#x263a</h1>\x{0420}";
is(length($doc), 46);

$p->parse($doc)->eof;

#use Data::Dump; Data::Dump::dump(@parsed);

is(@parsed, 9);
is($parsed[0][0], "start_document");

is($parsed[1][0], "start");
is($parsed[1][1], "<title>");
SKIP: { skip "no utf8::is_utf8", 1 if !defined(&utf8::is_utf8); ok(utf8::is_utf8($parsed[1][1]), "is_utf8") };
is($parsed[1][3], 0);
is($parsed[1][4], 7);

is($parsed[2][0], "text");
is(ord($parsed[2][1]), 0x263A);
is($parsed[2][2], chr(0x263A));
is($parsed[2][3], 7);
is($parsed[2][4], 1);
is($parsed[2][5], 8);
is($parsed[2][6], 7);

is($parsed[3][0], "end");
is($parsed[3][1], "</title>");
is($parsed[3][3], 8);
is($parsed[3][6], 8);

is($parsed[4][0], "start");
is($parsed[4][1], "<h1 id=\x{2600} f>");
is(join("|", @{$parsed[4][7]}), "1|2|4|2|7|1|9|1|0|0");
is($parsed[4][8]{id}, "\x{2600}");

is($parsed[5][0], "text");
is($parsed[5][1], "Smile &#x263a");
is($parsed[5][2], "Smile \x{263A}");

is($parsed[7][0], "text");
is($parsed[7][1], "\x{0420}");
is($parsed[7][2], "\x{0420}");

is($parsed[8][0], "end_document");
is($parsed[8][3], length($doc));
is($parsed[8][5], length($doc));
is($parsed[8][6], length($doc));
is(@warn, 0);

# Try to parse it as an UTF8 encoded string
utf8::encode($doc);
is(length($doc), 51);

@parsed = ();
$p->parse($doc)->eof;

#use Data::Dump; Data::Dump::dump(@parsed);

is(@parsed, 9);
is($parsed[0][0], "start_document");

is($parsed[1][0], "start");
is($parsed[1][1], "<title>");
SKIP: { skip "no utf8::is_utf8", 1 if !defined(&utf8::is_utf8); ok(!utf8::is_utf8($parsed[1][1]), "!is_utf8") };
is($parsed[1][3], 0);
is($parsed[1][4], 7);

is($parsed[2][0], "text");
is(ord($parsed[2][1]), 226);
is($parsed[2][1], "\xE2\x98\xBA");
is($parsed[2][2], "\xE2\x98\xBA");
is($parsed[2][3], 7);
is($parsed[2][4], 3);
is($parsed[2][5], 10);
is($parsed[2][6], 7);

is($parsed[3][0], "end");
is($parsed[3][1], "</title>");
is($parsed[3][3], 10);
is($parsed[3][6], 10);

is($parsed[4][0], "start");
is($parsed[4][1], "<h1 id=\xE2\x98\x80 f>");
is(join("|", @{$parsed[4][7]}), "1|2|4|2|7|3|11|1|0|0");
is($parsed[4][8]{id}, "\xE2\x98\x80");

is($parsed[5][0], "text");
is($parsed[5][1], "Smile &#x263a");
is($parsed[5][2], "Smile \x{263A}");

is($parsed[8][0], "end_document");
is($parsed[8][3], length($doc));
is($parsed[8][5], length($doc));
is($parsed[8][6], length($doc));

is(@warn, 1);
like($warn[0], qr/^Parsing of undecoded UTF-8 will give garbage when decoding entities/);

my $file = "test-$$.html";
open(my $fh, ">:utf8", $file) || die;
print $fh <<EOT;
\x{FEFF}
<title>\x{263A} Love! </title>
<h1 id=&hearts;\x{2665}>&hearts; Love \x{2665}<h1>
EOT
close($fh) || die;

@warn = ();
@parsed = ();
$p->parse_file($file);
is(@parsed, "11");
is($parsed[6][0], "start");
is($parsed[6][8]{id}, "\x{2665}\xE2\x99\xA5");
is($parsed[7][0], "text");
is($parsed[7][1], "&hearts; Love \xE2\x99\xA5");
is($parsed[7][2], "\x{2665} Love \xE2\x99\xA5");  # expected garbage
is($parsed[10][3], -s $file);
is(@warn, 1);
like($warn[0], qr/^Parsing of undecoded UTF-8 will give garbage when decoding entities/);

@warn = ();
@parsed = ();
open($fh, "<:raw:utf8", $file) || die;
$p->parse_file($fh);
is(@parsed, "11");
is($parsed[6][0], "start");
is($parsed[6][8]{id}, "\x{2665}\x{2665}");
is($parsed[7][0], "text");
is($parsed[7][1], "&hearts; Love \x{2665}");
is($parsed[7][2], "\x{2665} Love \x{2665}");
is($parsed[10][3], (-s $file) - 2 * 4);
is(@warn, 0);

@warn = ();
@parsed = ();
open($fh, "<:raw", $file) || die;
$p->utf8_mode(1);
$p->parse_file($fh);
is(@parsed, "11");
is($parsed[6][0], "start");
is($parsed[6][8]{id}, "\xE2\x99\xA5\xE2\x99\xA5");
is($parsed[7][0], "text");
is($parsed[7][1], "&hearts; Love \xE2\x99\xA5");
is($parsed[7][2], "\xE2\x99\xA5 Love \xE2\x99\xA5");
is($parsed[10][3], -s $file);
is(@warn, 0);

unlink($file);

@parsed = ();
$p->parse(q(<a href="a=1&lang=2&times=3">foo</a>))->eof;
is(@parsed, "5");
is($parsed[1][0], "start");
is($parsed[1][8]{href}, "a=1&lang=2\xd7=3");

ok(!HTML::Entities::_probably_utf8_chunk(""));
ok(!HTML::Entities::_probably_utf8_chunk("f"));
ok(HTML::Entities::_probably_utf8_chunk("f\xE2\x99\xA5"));
ok(HTML::Entities::_probably_utf8_chunk("f\xE2\x99\xA5o"));
ok(HTML::Entities::_probably_utf8_chunk("f\xE2\x99\xA5o\xE2"));
ok(HTML::Entities::_probably_utf8_chunk("f\xE2\x99\xA5o\xE2\x99"));
ok(!HTML::Entities::_probably_utf8_chunk("f\xE2"));
ok(!HTML::Entities::_probably_utf8_chunk("f\xE2\x99"));
}
