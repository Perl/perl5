BEGIN {
    unless ("A" eq pack('U', 0x41)) {
	print "1..0 # Unicode::Collate " .
	    "cannot stringify a Unicode code point\n";
	exit 0;
    }
    if ($ENV{PERL_CORE}) {
	chdir('t') if -d 't';
	@INC = $^O eq 'MacOS' ? qw(::lib) : qw(../lib);
    }
}

use Test;
BEGIN { plan tests => 57 };

use strict;
use warnings;
use Unicode::Collate;

ok(1);

##### 2..6

my $overCJK = Unicode::Collate->new(
  table => undef,
  normalization => undef,
  entry => <<'ENTRIES',
0061 ; [.0101.0020.0002.0061] # latin a
0041 ; [.0101.0020.0008.0041] # LATIN A
4E00 ; [.B1FC.0030.0004.4E00] # Ideograph; B1FC = FFFF - 4E03.
ENTRIES
  overrideCJK => sub {
    my $u = 0xFFFF - $_[0]; # reversed
    [$u, 0x20, 0x2, $u];
  },
);

ok($overCJK->lt("a", "A")); # diff. at level 3.
ok($overCJK->lt( "\x{4E03}",  "\x{4E00}")); # diff. at level 2.
ok($overCJK->lt("A\x{4E03}", "A\x{4E00}"));
ok($overCJK->lt("A\x{4E03}", "a\x{4E00}"));
ok($overCJK->lt("a\x{4E03}", "A\x{4E00}"));

##### 7..17
ok($overCJK->gt("a\x{3400}", "A\x{4DB5}"));
ok($overCJK->gt("a\x{4DB5}", "A\x{9FA5}"));
ok($overCJK->gt("a\x{9FA5}", "A\x{9FA6}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FA6}", "A\x{9FBB}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FBB}", "A\x{9FBC}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FBC}", "A\x{9FBF}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FBF}", "A\x{9FC3}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FC3}", "A\x{9FC4}")); # UI since Unicode 5.2.0
ok($overCJK->gt("a\x{9FC4}", "A\x{9FCB}")); # UI since Unicode 5.2.0
ok($overCJK->lt("a\x{9FCB}", "A\x{9FCC}"));
ok($overCJK->lt("a\x{9FC4}", "A\x{9FCF}"));

##### 18..26
$overCJK->change(UCA_Version => 9);
ok($overCJK->gt("a\x{3400}", "A\x{4DB5}"));
ok($overCJK->gt("a\x{4DB5}", "A\x{9FA5}"));
ok($overCJK->lt("a\x{9FA5}", "A\x{9FA6}"));
ok($overCJK->lt("a\x{9FA6}", "A\x{9FBB}"));
ok($overCJK->lt("a\x{9FBB}", "A\x{9FBC}"));
ok($overCJK->lt("a\x{9FBC}", "A\x{9FBF}"));
ok($overCJK->lt("a\x{9FBF}", "A\x{9FC3}"));
ok($overCJK->lt("a\x{9FC3}", "A\x{9FC4}"));
ok($overCJK->lt("a\x{9FC4}", "A\x{9FCF}"));

##### 27..35
$overCJK->change(UCA_Version => 14);
ok($overCJK->gt("a\x{3400}", "A\x{4DB5}"));
ok($overCJK->gt("a\x{4DB5}", "A\x{9FA5}"));
ok($overCJK->gt("a\x{9FA5}", "A\x{9FA6}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FA6}", "A\x{9FBB}")); # UI since Unicode 4.1.0
ok($overCJK->lt("a\x{9FBB}", "A\x{9FBC}"));
ok($overCJK->lt("a\x{9FBC}", "A\x{9FBF}"));
ok($overCJK->lt("a\x{9FBF}", "A\x{9FC3}"));
ok($overCJK->lt("a\x{9FC3}", "A\x{9FC4}"));
ok($overCJK->lt("a\x{9FC4}", "A\x{9FCF}"));

##### 36..46
$overCJK->change(UCA_Version => 18);
ok($overCJK->gt("a\x{3400}", "A\x{4DB5}"));
ok($overCJK->gt("a\x{4DB5}", "A\x{9FA5}"));
ok($overCJK->gt("a\x{9FA5}", "A\x{9FA6}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FA6}", "A\x{9FBB}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FBB}", "A\x{9FBC}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FBC}", "A\x{9FBF}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FBF}", "A\x{9FC3}")); # UI since Unicode 5.1.0
ok($overCJK->lt("a\x{9FC3}", "A\x{9FC4}"));
ok($overCJK->lt("a\x{9FC3}", "A\x{9FCB}"));
ok($overCJK->lt("a\x{9FC3}", "A\x{9FCC}"));
ok($overCJK->lt("a\x{9FC4}", "A\x{9FCF}"));

##### 47..57
$overCJK->change(UCA_Version => 20);
ok($overCJK->gt("a\x{3400}", "A\x{4DB5}"));
ok($overCJK->gt("a\x{4DB5}", "A\x{9FA5}"));
ok($overCJK->gt("a\x{9FA5}", "A\x{9FA6}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FA6}", "A\x{9FBB}")); # UI since Unicode 4.1.0
ok($overCJK->gt("a\x{9FBB}", "A\x{9FBC}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FBC}", "A\x{9FBF}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FBF}", "A\x{9FC3}")); # UI since Unicode 5.1.0
ok($overCJK->gt("a\x{9FC3}", "A\x{9FC4}")); # UI since Unicode 5.2.0
ok($overCJK->gt("a\x{9FC4}", "A\x{9FCB}")); # UI since Unicode 5.2.0
ok($overCJK->lt("a\x{9FCB}", "A\x{9FCC}"));
ok($overCJK->lt("a\x{9FC4}", "A\x{9FCF}"));

