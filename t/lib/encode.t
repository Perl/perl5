BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\Encode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
}
use Test;
use Encode qw(from_to);
use charnames qw(greek);
my @encodings = grep(/iso8859/,Encode::encodings());
my $n = 2;
my @character_set = ('0'..'9', 'A'..'Z', 'a'..'z');
my @source = qw(ascii iso8859-1 cp1250);
my @destiny = qw(cp1047 cp37 posix-bc);
my @ebcdic_sets = qw(cp1047 cp37 posix-bc);
plan test => 21+$n*@encodings + 2*@source*@destiny*@character_set + 2*@ebcdic_sets*256;
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
ok("\N{alpha}",substr($uni,0,1),"alpha does not map to symbol 'a'");
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

# On ASCII based machines see if we can map several codepoints from
# three distinct ASCII sets to three distinct EBCDIC coded character sets.
# On EBCDIC machines see if we can map from three EBCDIC sets to three
# distinct ASCII sets.

my @expectation = (240..249, 193..201,209..217,226..233, 129..137,145..153,162..169);
if (ord('A') != 65) {
    my @temp = @destiny;
    @destiny = @source;
    @source = @temp;
    undef(@temp);
    @expectation = (48..57, 65..90, 97..122);
}

foreach my $to (@destiny)
 {
  foreach my $from (@source)
   {
    my @expected = @expectation;
    foreach my $chr (@character_set)
     {
      my $native_chr = $chr;
      my $cpy = $chr;
      my $rc = from_to($cpy,$from,$to);
      ok(1,$rc,"Could not translate from $from to $to");
      ok(ord($cpy),shift(@expected),"mangled translating $native_chr from $from to $to");
     }
   }
 }

# On either ASCII or EBCDIC machines ensure we can take the full one
# byte repetoire to EBCDIC sets and back.

my $enc_as = 'iso8859-1';
foreach my $enc_eb (@ebcdic_sets)
 {
  foreach my $ord (0..255)
   {
    $str = chr($ord);
    my $rc = from_to($str,$enc_as,$enc_eb);
    $rc += from_to($str,$enc_eb,$enc_as);
    ok($rc,2,"return code for $ord $enc_eb -> $enc_as -> $enc_eb was not obtained");
    ok($ord,ord($str),"$enc_as mangled translating $ord to $enc_eb and back");
   }
 }

for $i (256,128,129,256)
 {
  my $c = chr($i);
  my $s = "$c\n".sprintf("%02X",$i);
  ok(Encode::valid_utf8($s),1,"concat of $i botched");
  Encode::utf8_upgrade($s);
  ok(Encode::valid_utf8($s),1,"concat of $i botched");
 }

