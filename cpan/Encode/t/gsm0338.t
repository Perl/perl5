BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    $| = 1;
}

use strict;
use utf8;
use Test::More tests => 776;
use Encode;
use Encode::GSM0338;

my $chk = Encode::LEAVE_SRC();

# escapes
# see https://www.3gpp.org/dynareport/23038.htm
# see https://www.etsi.org/deliver/etsi_ts/123000_123099/123038/15.00.00_60/ts_123038v150000p.pdf (page 22)
my %esc_seq = (
	       "\x{20ac}" => "\x1b\x65",
	       "\x0c"     => "\x1b\x0A",
	       "["        => "\x1b\x3C",
	       "\\"       => "\x1b\x2F",
	       "]"        => "\x1b\x3E",
	       "^"        => "\x1b\x14",
	       "{"        => "\x1b\x28",
	       "|"        => "\x1b\x40",
	       "}"        => "\x1b\x29",
	       "~"        => "\x1b\x3D",
);

my %unesc_seq = reverse %esc_seq;


sub eu{
    $_[0] =~ /[\x00-\x1f]/ ? 
	sprintf("\\x{%04X}", ord($_[0])) : encode_utf8($_[0]);
 
}

for my $c ( map { chr } 0 .. 127 ) {
    next if $c eq "\x1B"; # escape character, start of multibyte sequence
    my $u = $Encode::GSM0338::GSM2UNI{$c};

    # default character set
    is decode( "gsm0338", $c, $chk ), $u,
      sprintf( "decode \\x%02X", ord($c) );
    eval { decode( "gsm0338", $c . "\xff", $chk | Encode::FB_CROAK ) };
    ok( $@, $@ );
    is encode( "gsm0338", $u, $chk ), $c, sprintf( "encode %s", eu($u) );
    eval { encode( "gsm0338", $u . "\x{3000}", $chk | Encode::FB_CROAK ) };
    ok( $@, $@ );

        is decode( "gsm0338", "\x00" . $c ), '@' . decode( "gsm0338", $c ),
          sprintf( '@: decode \x00+\x%02X', ord($c) );

    # escape seq.
    my $ecs = "\x1b" . $c;
    if ( $unesc_seq{$ecs} ) {
        is decode( "gsm0338", $ecs, $chk ), $unesc_seq{$ecs},
          sprintf( "ESC: decode ESC+\\x%02X", ord($c) );
        is encode( "gsm0338", $unesc_seq{$ecs}, $chk ), $ecs,
          sprintf( "ESC: encode %s ", eu( $unesc_seq{$ecs} ) );
    }
    else {
        is decode( "gsm0338", $ecs, $chk ),
          "\x{FFFD}",
          sprintf( "decode ESC+\\x%02X", ord($c) );
    }
}

# https://rt.cpan.org/Ticket/Display.html?id=75670
is decode("gsm0338", "\x09") => chr(0xC7), 'RT75670: decode';
is encode("gsm0338", chr(0xC7)) => "\x09", 'RT75670: encode';

# https://rt.cpan.org/Public/Bug/Display.html?id=124571
is decode("gsm0338", encode('gsm0338', '..@@..')), '..@@..';
is decode("gsm0338", encode('gsm0338', '..@€..')), '..@€..';

__END__
for my $c (map { chr } 0..127){
    my $b = "\x1b$c";
    my $u =  $Encode::GSM0338::GSM2UNI{$b};
    next unless $u;
    $u ||= "\xA0" . $Encode::GSM0338::GSM2UNI{$c};
    is decode("gsm0338", $b), $u, sprintf("decode ESC+\\x%02X", ord($c) );
}

__END__
# old test follows
ub t { is(decode("gsm0338", my $t = $_[0]), $_[1]) }

# t("\x00",     "\x00"); # ???

# "Round-trip".
t("\x41",     "\x41");

t("\x01",     "\xA3");
t("\x02",     "\x24");
t("\x03",     "\xA5");
t("\x09",     "\xE7");

t("\x00\x00", "\x00\x00"); # Maybe?
t("\x00\x1B", "\x40\xA0"); # Maybe?
t("\x00\x41", "\x40\x41");

# t("\x1B",     "\x1B"); # ???

# Escape with no special second byte is just a NBSP.
t("\x1B\x41", "\xA0\x41");

t("\x1B\x00", "\xA0\x40"); # Maybe?

# Special escape characters.
t("\x1B\x0A", "\x0C");
t("\x1B\x14", "\x5E");
t("\x1B\x28", "\x7B");
t("\x1B\x29", "\x7D");
t("\x1B\x2F", "\x5C");
t("\x1B\x3C", "\x5B");
t("\x1B\x3D", "\x7E");
t("\x1B\x3E", "\x5D");
t("\x1B\x40", "\x7C");
t("\x1B\x40", "\x7C");
t("\x1B\x65", "\x{20AC}");
