
BEGIN {
    unless ("A" eq pack('U', 0x41)) {
	print "1..0 # Unicode::Collate " .
	    "cannot stringify a Unicode code point\n";
	exit 0;
    }
}

BEGIN {
    if ($ENV{PERL_CORE}) {
        chdir('t') if -d 't';
        @INC = $^O eq 'MacOS' ? qw(::lib) : qw(../lib);
    }
}

use Test;
use strict;
use warnings;

BEGIN {
    use Unicode::Collate;

    unless (exists &Unicode::Collate::bootstrap or 5.008 <= $]) {
	print "1..0 # skipped: XSUB, or Perl 5.8.0 or later".
		" needed for this test\n";
	print $@;
	exit;
    }
}

BEGIN { plan tests => 22 };

ok(1);

#########################

no warnings 'utf8';

# NULL is tailorable but illegal code points are not.
# illegal code points should be always ingored
# (cf. UCA, 7.1.1 Illegal code points).

my $illeg = Unicode::Collate->new(
  entry => <<'ENTRIES',
0000  ; [.0020.0000.0000.0000] # [0000] NULL
0001  ; [.0021.0000.0000.0001] # [0001] START OF HEADING
FFFE  ; [.0022.0000.0000.FFFE] # <noncharacter-FFFE>
FFFF  ; [.0023.0000.0000.FFFF] # <noncharacter-FFFF>
D800  ; [.0024.0000.0000.D800] # <surrogate-D800>
DFFF  ; [.0025.0000.0000.DFFF] # <surrogate-DFFF>
FDD0  ; [.0026.0000.0000.FDD0] # <noncharacter-FDD0>
FDEF  ; [.0027.0000.0000.FDEF] # <noncharacter-FDEF>
0002  ; [.0030.0000.0000.0002] # [0002] START OF TEXT
10FFFF; [.0040.0000.0000.10FFFF] # <noncharacter-10FFFF>
110000; [.0041.0000.0000.110000] # <out-of-range 110000>
ENTRIES
  level => 1,
  table => undef,
  normalization => undef,
);

ok($illeg->lt("", "\x00"));
ok($illeg->lt("", "\x01"));
ok($illeg->eq("", "\x{FFFE}"));
ok($illeg->eq("", "\x{FFFF}"));
ok($illeg->eq("", "\x{D800}"));
ok($illeg->eq("", "\x{DFFF}"));
ok($illeg->eq("", "\x{FDD0}"));
ok($illeg->eq("", "\x{FDEF}"));
ok($illeg->lt("", "\x02"));
ok($illeg->eq("", "\x{10FFFF}"));
ok($illeg->eq("", "\x{110000}"));

ok($illeg->lt("\x00", "\x01"));
ok($illeg->lt("\x01", "\x02"));
ok($illeg->ne("\0", "\x{D800}"));
ok($illeg->ne("\0", "\x{DFFF}"));
ok($illeg->ne("\0", "\x{FDD0}"));
ok($illeg->ne("\0", "\x{FDEF}"));
ok($illeg->ne("\0", "\x{FFFE}"));
ok($illeg->ne("\0", "\x{FFFF}"));
ok($illeg->ne("\0", "\x{10FFFF}"));
ok($illeg->ne("\0", "\x{110000}"));

