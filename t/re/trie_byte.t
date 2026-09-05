#!./perl

BEGIN {
    ${^RE_TRIE_MAXBUF} = 65536;
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}

use strict;
use warnings;

plan tests => 35;

my $trie = qr/(?:ab|ac|ad|ae)/;

ok('ab' =~ $trie, 'ASCII trie matches a native target');
ok('ac' =~ $trie, 'ASCII trie matches another native alternative');
ok('ae' =~ $trie, 'ASCII trie matches the final native alternative');

my $utf8 = 'ad';
utf8::upgrade($utf8);
ok($utf8 =~ $trie, 'ASCII trie matches an UTF-8 target');

my $nonmatch = 'af';
ok($nonmatch !~ $trie, 'ASCII trie rejects a non-matching native target');

my $native_utf8_looking = pack('C*', 0xc3, 0xa9);
my $native_utf8_looking_trie = qr/(?:\Q$native_utf8_looking\E|abc)/;
ok($native_utf8_looking =~ $native_utf8_looking_trie,
   'native octets that look like UTF-8 remain separate trie characters');

my $unicode_trie = qr/(?:\x{e9}|\x{3a9}|abc)/;
my $latin1 = pack('C', 0xe9);
ok($latin1 =~ $unicode_trie, 'UTF-8 byte trie accepts a native Latin-1 byte');

my $wide = "\x{3a9}";
utf8::upgrade($wide);
ok($wide =~ $unicode_trie, 'UTF-8 byte trie accepts a wide UTF-8 character');

ok('abc' =~ $unicode_trie, 'UTF-8 byte trie retains ASCII alternatives');

my $fold_trie = qr/(?:foo|bar|baz)/i;
ok('BAR' =~ $fold_trie, 'folded ASCII trie matches a native target');
my $fold_utf8 = "ω";
utf8::upgrade($fold_utf8);
ok($fold_utf8 =~ qr/(?:Ω|ω|abc)/i,
   'folded UTF-8 trie matches a Unicode target');

my $sharp_s = "\x{df}";
utf8::upgrade($sharp_s);
ok("ba$sharp_s" =~ qr/(?:foo|Ba$sharp_s|bar)/i,
   'folded trie preserves multi-character sharp-s folds');

ok('abd' =~ qr/(?:abc|abd|abe)/,
   'ASCII-safe common prefixes remain valid in byte tries');

# Keep several byte tries alive at once, then execute them repeatedly.  This
# mirrors the benchmark workload and exercises trie ownership as well as the
# transition path.
my $wide_alphabet = qr/(?:alpha|alpine|altar|algebra|almanac|aloe|alter|altruist)/;
my $omega = chr 0x3A9;
my $mu = chr 0x3BC;
my $capital_mu = chr 0x39C;
my $grinning = chr 0x1F600;
my $han = chr 0x4E2D;
my $country = chr 0x56FD;
my $micro_sign = chr 0xB5;
my $angstrom = chr 0xC5;
my $e_acute = chr 0xE9;
my $kelvin = chr 0x212A;
my $wide_sharp_s = chr 0xDF;
my $utf8_prefix = qr/(?:\Q$omega\Ex|\Q$omega\Ey)/u;
my $han_country = $han . $country;
my $wide_codepoints = qr/(?:\Q$omega\Emega|\Q$mu\Eicro|\Q$grinning\Eface|\Q$han_country\E|cafe)/u;
my $mixed = qr/(?:abc|\Q$e_acute\Eclair|\Q$omega\Emega|abacus|\Q$han_country\E)/u;
my $unicode_fold = qr/(?:\Q$capital_mu\Eu|\Q$mu\Eu|\Q$kelvin\Eelvin|kelvin|Stra\Q$wide_sharp_s\Ee)/iu;
my $latin1_fold = qr/(?:\Q$micro_sign\Eunit|\Q$capital_mu\Eunit|\Q$angstrom\Engstrom|\x{212B}ngstrom)/iu;

ok(($omega . 'mega') =~ qr/\Q$omega\Emega/u,
   'control exact matches a two-byte UTF-8 character');
ok(($grinning . 'face') =~ qr/\Q$grinning\Eface/u,
   'control exact matches a supplementary UTF-8 character');
ok(($omega . 'x') =~ $utf8_prefix,
   'UTF-8 prefix extraction matches its first alternative');
ok(($omega . 'y') =~ $utf8_prefix,
   'UTF-8 prefix extraction matches its second alternative');

my $wide_hits = 0;
my $mixed_hits = 0;
my $unicode_fold_hits = 0;
my $latin1_fold_hits = 0;
for (1 .. 1000) {
    $wide_hits += ($_ =~ $wide_alphabet) for qw(alpine altar almanac alter absent);
    for my $s ($omega . 'mega', $mu . 'icro', $grinning . 'face', 'nope') {
        $wide_hits += ($s =~ $wide_codepoints);
    }
    for my $s ('abc', 'abacus', $e_acute . 'clair', $omega . 'mega', 'none') {
        $mixed_hits += ($s =~ $mixed);
    }
    for my $s ($mu . 'u', $capital_mu . 'u', 'KELVIN', 'strasse', 'nothing') {
        $unicode_fold_hits += ($s =~ $unicode_fold);
    }
    for my $s ($micro_sign . 'unit', $capital_mu . 'unit', $angstrom . 'ngstrom', 'nothing') {
        $latin1_fold_hits += ($s =~ $latin1_fold);
    }
}

ok($wide_hits == 7000, 'wide trie survives repeated execution');
ok($mixed_hits == 4000, 'mixed byte trie survives repeated execution');
ok($unicode_fold_hits == 4000, 'Unicode folded trie survives repeated execution');
ok($latin1_fold_hits == 3000, 'Latin-1 folded trie survives repeated execution');

ok(($omega . 'mega') =~ $wide_codepoints,
   'wide-codepoint trie matches after other tries execute');
ok('strasse' =~ $unicode_fold,
   'Unicode folded trie matches after repeated execution');
ok(($angstrom . 'ngstrom') =~ $latin1_fold,
   'Latin-1 folded trie matches after repeated execution');
ok('altruist' =~ $wide_alphabet,
   'wide ASCII trie retains its final alternative');
ok('abacus' =~ $mixed,
   'mixed trie retains its ASCII alternative');
ok(($grinning . 'face') =~ $wide_codepoints,
   'wide trie retains its supplementary-plane alternative');

ok(($omega . 'mega') =~ $wide_codepoints,
   'wide trie matches the Greek capital omega alternative');
ok(($mu . 'icro') =~ $wide_codepoints,
   'wide trie matches the Greek small mu alternative');
ok(($e_acute . 'clair') =~ $mixed,
   'mixed trie matches the Latin-1 alternative');
ok(($omega . 'mega') =~ $mixed,
   'mixed trie matches the Greek alternative');
ok(($mu . 'u') =~ $unicode_fold,
   'Unicode fold trie matches the small-mu alternative');
ok(($capital_mu . 'u') =~ $unicode_fold,
   'Unicode fold trie matches the capital-mu alternative');
ok('KELVIN' =~ $unicode_fold,
   'Unicode fold trie matches the Kelvin alternative');
ok('strasse' =~ $unicode_fold,
   'Unicode fold trie matches the sharp-s expansion alternative');
