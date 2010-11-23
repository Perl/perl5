
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
BEGIN { plan tests => 130 };

use strict;
use warnings;
use Unicode::Collate::Locale;

ok(1);

#########################

my $objBe = Unicode::Collate::Locale->
    new(locale => 'BE', normalization => undef);

ok($objBe->getlocale, 'be');

$objBe->change(level => 1);

ok($objBe->gt("\x{4E5}", "\x{438}"));
ok($objBe->gt("\x{4E4}", "\x{418}"));
ok($objBe->gt("\x{439}", "\x{438}"));
ok($objBe->gt("\x{419}", "\x{418}"));

# 6

ok($objBe->eq("\x{4D1}", "\x{430}"));
ok($objBe->eq("\x{4D0}", "\x{410}"));
ok($objBe->eq("\x{4D3}", "\x{430}"));
ok($objBe->eq("\x{4D2}", "\x{410}"));
ok($objBe->eq("\x{453}", "\x{433}"));
ok($objBe->eq("\x{403}", "\x{413}"));
ok($objBe->eq("\x{4D7}", "\x{435}"));
ok($objBe->eq("\x{4D6}", "\x{415}"));
ok($objBe->eq("\x{4DD}", "\x{436}"));
ok($objBe->eq("\x{4DC}", "\x{416}"));
ok($objBe->eq("\x{4DF}", "\x{437}"));
ok($objBe->eq("\x{4DE}", "\x{417}"));
ok($objBe->eq("\x{457}", "\x{456}"));
ok($objBe->eq("\x{407}", "\x{406}"));
ok($objBe->eq("\x{4E7}", "\x{43E}"));
ok($objBe->eq("\x{4E6}", "\x{41E}"));
ok($objBe->eq("\x{45C}", "\x{43A}"));
ok($objBe->eq("\x{40C}", "\x{41A}"));
ok($objBe->eq("\x{45E}", "\x{443}"));
ok($objBe->eq("\x{40E}", "\x{423}"));
ok($objBe->eq("\x{4F1}", "\x{443}"));
ok($objBe->eq("\x{4F0}", "\x{423}"));
ok($objBe->eq("\x{4F3}", "\x{443}"));
ok($objBe->eq("\x{4F2}", "\x{423}"));
ok($objBe->eq("\x{4F5}", "\x{447}"));
ok($objBe->eq("\x{4F4}", "\x{427}"));
ok($objBe->eq("\x{4F9}", "\x{44B}"));
ok($objBe->eq("\x{4F8}", "\x{42B}"));
ok($objBe->eq("\x{4ED}", "\x{44D}"));
ok($objBe->eq("\x{4EC}", "\x{42D}"));

# 36

$objBe->change(level => 2);

ok($objBe->gt("\x{4D1}", "\x{430}"));
ok($objBe->gt("\x{4D0}", "\x{410}"));
ok($objBe->gt("\x{4D3}", "\x{430}"));
ok($objBe->gt("\x{4D2}", "\x{410}"));
ok($objBe->gt("\x{453}", "\x{433}"));
ok($objBe->gt("\x{403}", "\x{413}"));
ok($objBe->gt("\x{4D7}", "\x{435}"));
ok($objBe->gt("\x{4D6}", "\x{415}"));
ok($objBe->gt("\x{4DD}", "\x{436}"));
ok($objBe->gt("\x{4DC}", "\x{416}"));
ok($objBe->gt("\x{4DF}", "\x{437}"));
ok($objBe->gt("\x{4DE}", "\x{417}"));
ok($objBe->gt("\x{457}", "\x{456}"));
ok($objBe->gt("\x{407}", "\x{406}"));
ok($objBe->gt("\x{4E7}", "\x{43E}"));
ok($objBe->gt("\x{4E6}", "\x{41E}"));
ok($objBe->gt("\x{45C}", "\x{43A}"));
ok($objBe->gt("\x{40C}", "\x{41A}"));
ok($objBe->gt("\x{45E}", "\x{443}"));
ok($objBe->gt("\x{40E}", "\x{423}"));
ok($objBe->gt("\x{4F1}", "\x{443}"));
ok($objBe->gt("\x{4F0}", "\x{423}"));
ok($objBe->gt("\x{4F3}", "\x{443}"));
ok($objBe->gt("\x{4F2}", "\x{423}"));
ok($objBe->gt("\x{4F5}", "\x{447}"));
ok($objBe->gt("\x{4F4}", "\x{427}"));
ok($objBe->gt("\x{4F9}", "\x{44B}"));
ok($objBe->gt("\x{4F8}", "\x{42B}"));
ok($objBe->gt("\x{4ED}", "\x{44D}"));
ok($objBe->gt("\x{4EC}", "\x{42D}"));

# 66

$objBe->change(level => 3);

ok($objBe->eq("\x{4D1}", "\x{430}\x{306}"));
ok($objBe->eq("\x{4D0}", "\x{410}\x{306}"));
ok($objBe->eq("\x{4D3}", "\x{430}\x{308}"));
ok($objBe->eq("\x{4D2}", "\x{410}\x{308}"));
ok($objBe->eq("\x{453}", "\x{433}\x{301}"));
ok($objBe->eq("\x{403}", "\x{413}\x{301}"));
ok($objBe->eq("\x{4D7}", "\x{435}\x{306}"));
ok($objBe->eq("\x{4D6}", "\x{415}\x{306}"));
ok($objBe->eq("\x{4DD}", "\x{436}\x{308}"));
ok($objBe->eq("\x{4DC}", "\x{416}\x{308}"));
ok($objBe->eq("\x{4DF}", "\x{437}\x{308}"));
ok($objBe->eq("\x{4DE}", "\x{417}\x{308}"));
ok($objBe->eq("\x{4E5}", "\x{438}\x{308}"));
ok($objBe->eq("\x{4E4}", "\x{418}\x{308}"));
ok($objBe->eq("\x{457}", "\x{456}\x{308}"));
ok($objBe->eq("\x{407}", "\x{406}\x{308}"));
ok($objBe->eq("\x{439}", "\x{438}\x{306}"));
ok($objBe->eq("\x{419}", "\x{418}\x{306}"));
ok($objBe->eq("\x{4E7}", "\x{43E}\x{308}"));
ok($objBe->eq("\x{4E6}", "\x{41E}\x{308}"));
ok($objBe->eq("\x{45C}", "\x{43A}\x{301}"));
ok($objBe->eq("\x{40C}", "\x{41A}\x{301}"));
ok($objBe->eq("\x{45E}", "\x{443}\x{306}"));
ok($objBe->eq("\x{40E}", "\x{423}\x{306}"));
ok($objBe->eq("\x{4F1}", "\x{443}\x{308}"));
ok($objBe->eq("\x{4F0}", "\x{423}\x{308}"));
ok($objBe->eq("\x{4F3}", "\x{443}\x{30B}"));
ok($objBe->eq("\x{4F2}", "\x{423}\x{30B}"));
ok($objBe->eq("\x{4F5}", "\x{447}\x{308}"));
ok($objBe->eq("\x{4F4}", "\x{427}\x{308}"));
ok($objBe->eq("\x{4F9}", "\x{44B}\x{308}"));
ok($objBe->eq("\x{4F8}", "\x{42B}\x{308}"));
ok($objBe->eq("\x{4ED}", "\x{44D}\x{308}"));
ok($objBe->eq("\x{4EC}", "\x{42D}\x{308}"));

# 100

ok($objBe->eq("\x{4D1}", "\x{430}\0\x{306}"));
ok($objBe->eq("\x{4D0}", "\x{410}\0\x{306}"));
ok($objBe->eq("\x{4D3}", "\x{430}\0\x{308}"));
ok($objBe->eq("\x{4D2}", "\x{410}\0\x{308}"));
ok($objBe->eq("\x{453}", "\x{433}\0\x{301}"));
ok($objBe->eq("\x{403}", "\x{413}\0\x{301}"));
ok($objBe->eq("\x{4D7}", "\x{435}\0\x{306}"));
ok($objBe->eq("\x{4D6}", "\x{415}\0\x{306}"));
ok($objBe->eq("\x{4DD}", "\x{436}\0\x{308}"));
ok($objBe->eq("\x{4DC}", "\x{416}\0\x{308}"));
ok($objBe->eq("\x{4DF}", "\x{437}\0\x{308}"));
ok($objBe->eq("\x{4DE}", "\x{417}\0\x{308}"));
ok($objBe->eq("\x{457}", "\x{456}\0\x{308}"));
ok($objBe->eq("\x{407}", "\x{406}\0\x{308}"));
ok($objBe->eq("\x{4E7}", "\x{43E}\0\x{308}"));
ok($objBe->eq("\x{4E6}", "\x{41E}\0\x{308}"));
ok($objBe->eq("\x{45C}", "\x{43A}\0\x{301}"));
ok($objBe->eq("\x{40C}", "\x{41A}\0\x{301}"));
ok($objBe->eq("\x{45E}", "\x{443}\0\x{306}"));
ok($objBe->eq("\x{40E}", "\x{423}\0\x{306}"));
ok($objBe->eq("\x{4F1}", "\x{443}\0\x{308}"));
ok($objBe->eq("\x{4F0}", "\x{423}\0\x{308}"));
ok($objBe->eq("\x{4F3}", "\x{443}\0\x{30B}"));
ok($objBe->eq("\x{4F2}", "\x{423}\0\x{30B}"));
ok($objBe->eq("\x{4F5}", "\x{447}\0\x{308}"));
ok($objBe->eq("\x{4F4}", "\x{427}\0\x{308}"));
ok($objBe->eq("\x{4F9}", "\x{44B}\0\x{308}"));
ok($objBe->eq("\x{4F8}", "\x{42B}\0\x{308}"));
ok($objBe->eq("\x{4ED}", "\x{44D}\0\x{308}"));
ok($objBe->eq("\x{4EC}", "\x{42D}\0\x{308}"));

# 130
