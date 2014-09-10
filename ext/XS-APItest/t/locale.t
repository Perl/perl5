BEGIN {
    require '../../t/test.pl';
    require '../../t/loc_tools.pl'; # to find locales
}

use XS::APItest;
use Config;

BEGIN {
    eval { require POSIX; POSIX->import("locale_h") };
    if ($@) {
	skip_all("could not load the POSIX module"); # running minitest?
    }
}

my @locales = eval { find_locales( &LC_NUMERIC ) };
skip_all("no locales available") unless @locales;

my $non_dot_locale;
for (@locales) {
    use locale;
    setlocale(LC_NUMERIC, $_) or next;
    my $in = 4.2; # avoid any constant folding bugs
    if (sprintf("%g", $in) ne "4.2") {
        $non_dot_locale = $_;
        last;
    }
}

skip_all("no non-dot radix locales available") unless $non_dot_locale;

plan tests => 2;

SKIP: {
      if ($Config{usequadmath}) {
            skip "no gconvert with usequadmath", 2;
      }
      is(test_Gconvert(4.179, 2), "4.2", "Gconvert doesn't recognize underlying locale outside 'use locale'");
      use locale;
      is(test_Gconvert(4.179, 2), "4.2", "Gconvert doesn't recognize underlying locale inside 'use locale'");
}
