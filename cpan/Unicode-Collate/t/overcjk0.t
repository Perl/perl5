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
BEGIN { plan tests => 66 };

use strict;
use warnings;
use Unicode::Collate;

ok(1);

##### 2..6

my $ignoreCJK = Unicode::Collate->new(
  table => undef,
  normalization => undef,
  overrideCJK => sub {()},
  entry => <<'ENTRIES',
5B57 ; [.0107.0020.0002.5B57]  # CJK Ideograph "Letter"
ENTRIES
);

# All CJK Unified Ideographs except U+5B57 are ignored.

ok($ignoreCJK->eq("\x{4E00}", ""));
ok($ignoreCJK->lt("\x{4E00}", "\0"));
ok($ignoreCJK->eq("Pe\x{4E00}rl", "Perl")); # U+4E00 is a CJK.
ok($ignoreCJK->gt("\x{4DFF}", "\x{4E00}")); # U+4DFF is not CJK.
ok($ignoreCJK->lt("Pe\x{5B57}rl", "Perl")); # 'r' is unassigned.

##### 7..20
ok($ignoreCJK->eq("\x{3400}", ""));
ok($ignoreCJK->eq("\x{4DB5}", ""));
ok($ignoreCJK->eq("\x{9FA5}", ""));
ok($ignoreCJK->eq("\x{9FA6}", "")); # UI since Unicode 4.1.0
ok($ignoreCJK->eq("\x{9FBB}", "")); # UI since Unicode 4.1.0
ok($ignoreCJK->eq("\x{9FBC}", "")); # UI since Unicode 5.1.0
ok($ignoreCJK->eq("\x{9FC3}", "")); # UI since Unicode 5.1.0
ok($ignoreCJK->eq("\x{9FC4}", "")); # UI since Unicode 5.2.0
ok($ignoreCJK->eq("\x{9FCB}", "")); # UI since Unicode 5.2.0
ok($ignoreCJK->gt("\x{9FCC}", "Perl"));
ok($ignoreCJK->eq("\x{20000}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->eq("\x{2A6D6}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->eq("\x{2A700}", "")); # ExtC since Unicode 5.2.0
ok($ignoreCJK->eq("\x{2B734}", "")); # ExtC since Unicode 5.2.0

##### 21..30
$ignoreCJK->change(UCA_Version => 8);
ok($ignoreCJK->eq("\x{3400}", ""));
ok($ignoreCJK->eq("\x{4DB5}", ""));
ok($ignoreCJK->eq("\x{9FA5}", ""));
ok($ignoreCJK->gt("\x{9FA6}", "Perl"));
ok($ignoreCJK->gt("\x{9FBB}", "Perl"));
ok($ignoreCJK->gt("\x{9FBC}", "Perl"));
ok($ignoreCJK->gt("\x{9FC3}", "Perl"));
ok($ignoreCJK->gt("\x{9FC4}", "Perl"));
ok($ignoreCJK->eq("\x{20000}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->eq("\x{2A6D6}", "")); # ExtB since Unicode 3.1.0

##### 31..40
$ignoreCJK->change(UCA_Version => 9);
ok($ignoreCJK->eq("\x{3400}", ""));
ok($ignoreCJK->eq("\x{4DB5}", ""));
ok($ignoreCJK->eq("\x{9FA5}", ""));
ok($ignoreCJK->gt("\x{9FA6}", "Perl"));
ok($ignoreCJK->gt("\x{9FBB}", "Perl"));
ok($ignoreCJK->gt("\x{9FBC}", "Perl"));
ok($ignoreCJK->gt("\x{9FC3}", "Perl"));
ok($ignoreCJK->gt("\x{9FC4}", "Perl"));
ok($ignoreCJK->eq("\x{20000}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->eq("\x{2A6D6}", "")); # ExtB since Unicode 3.1.0

##### 41..52
$ignoreCJK->change(UCA_Version => 14);
ok($ignoreCJK->eq("\x{3400}", ""));
ok($ignoreCJK->eq("\x{4DB5}", ""));
ok($ignoreCJK->eq("\x{9FA5}", ""));
ok($ignoreCJK->eq("\x{9FA6}", "")); # UI since Unicode 4.1.0
ok($ignoreCJK->eq("\x{9FBB}", "")); # UI since Unicode 4.1.0
ok($ignoreCJK->gt("\x{9FBC}", "Perl"));
ok($ignoreCJK->gt("\x{9FC3}", "Perl"));
ok($ignoreCJK->gt("\x{9FC4}", "Perl"));
ok($ignoreCJK->eq("\x{20000}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->eq("\x{2A6D6}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->gt("\x{2A700}", "Perl"));
ok($ignoreCJK->gt("\x{2B734}", "Perl"));

##### 53..66
$ignoreCJK->change(UCA_Version => 18);
ok($ignoreCJK->eq("\x{3400}", ""));
ok($ignoreCJK->eq("\x{4DB5}", ""));
ok($ignoreCJK->eq("\x{9FA5}", ""));
ok($ignoreCJK->eq("\x{9FA6}", "")); # UI since Unicode 4.1.0
ok($ignoreCJK->eq("\x{9FBB}", "")); # UI since Unicode 4.1.0
ok($ignoreCJK->eq("\x{9FBC}", "")); # UI since Unicode 5.1.0
ok($ignoreCJK->eq("\x{9FC3}", "")); # UI since Unicode 5.1.0
ok($ignoreCJK->gt("\x{9FC4}", "Perl"));
ok($ignoreCJK->gt("\x{9FCB}", "Perl"));
ok($ignoreCJK->gt("\x{9FCC}", "Perl"));
ok($ignoreCJK->eq("\x{20000}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->eq("\x{2A6D6}", "")); # ExtB since Unicode 3.1.0
ok($ignoreCJK->gt("\x{2A700}", "Perl"));
ok($ignoreCJK->gt("\x{2B734}", "Perl"));

