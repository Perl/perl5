BEGIN {
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
    unless (find PerlIO::Layer 'perlio') {
	print "1..0 # Skip: PerlIO was not built\n";
	exit 0;
    }
    if (ord("A") == 193) {
	print "1..0 # encoding pragma does not support EBCDIC platforms\n";
	exit(0);
    }
}

use encoding 'utf8';

my @c = (127, 128, 255, 256);

print "1.." . (scalar @c + 1) . "\n";

my @f;

for my $i (0..$#c) {
  push @f, "f$i";
  open(F, ">f$i") or die "$0: failed to open 'f$i' for writing: $!";
  binmode(F, ":utf8");
  print F chr($c[$i]);
  close F;
}

my $t = 1;

for my $i (0..$#c) {
  open(F, "<f$i") or die "$0: failed to open 'f$i' for reading: $!";
  binmode(F, ":utf8");
  my $c = <F>;
  my $o = ord($c);
  print $o == $c[$i] ? "ok $t\n" : "not ok $t # $o != $c[$i]\n";
  $t++;
}

my $f = "f4";

push @f, $f;
open(F, ">$f") or die "$0: failed to open '$f' for writing: $!";
binmode(F, ":raw"); # Output raw bytes.
print F chr(128); # Output illegal UTF-8.
close F;
open(F, $f) or die "$0: failed to open '$f' for reading: $!";
binmode(F, ":encoding(utf-8)");
{
	local $^W = 1;
	local $SIG{__WARN__} = sub { $a = shift };
	eval { <F> }; # This should get caught.
}
print $a =~ qr{^utf8 "\\x80" does not map to Unicode} ?
  "ok $t\n" : "not ok $t: $a\n";

END {
  1 while unlink @f;
}
