BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}
use Test;
use Encode qw(from_to);
use charnames qw(greek);
my @encodings = grep(/iso8859/,Encode::encodings());
my $n = 2;
plan test => 13+$n*@encodings;
my $str = join('',map(chr($_),0x20..0x7E));
my $cpy = $str;
ok(length($str),from_to($cpy,'iso8859-1','Unicode'),"Length Wrong");
ok($cpy,$str,"ASCII mangled by translating from iso8859-1 to Unicode");
$cpy = $str;
ok(from_to($cpy,'Unicode','iso8859-1'),length($str),"Length wrong");
ok($cpy,$str,"ASCII mangled by translating from Unicode to iso8859-1");

$str = join('',map(chr($_),0xa0..0xff));
$cpy = $str;
ok(length($str),from_to($cpy,'iso8859-1','Unicode'),"Length Wrong");

my $sym = Encode->getEncoding('symbol');
my $uni = $sym->toUnicode('a');
ok("\N{alpha}",substr($uni,0,1),"alpha does not map so symbol 'a'");
$str = $sym->fromUnicode("\N{Beta}");
ok("B",substr($str,0,1),"Symbol 'B' does not map to Beta");

foreach my $enc (qw(symbol dingbats ascii),@encodings)
 {
  my $tab = Encode->getEncoding($enc);
  ok(1,defined($tab),"Could not load $enc");
  $str = join('',map(chr($_),0x20..0x7E));
  $uni = $tab->toUnicode($str);
  $cpy = $tab->fromUnicode($uni);
  ok($cpy,$str,"$enc mangled translating to Unicode and back");
 }

