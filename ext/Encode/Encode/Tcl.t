BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
}
use Test;
use Encode qw(encode decode);
use Encode::Tcl;

my @encodings = qw(euc-cn euc-jp euc-kr big5 shiftjis); # CJK
my $n = 2;

my %greek = (
  'euc-cn'   => [0xA6A1..0xA6B8,0xA6C1..0xA6D8],
  'euc-jp'   => [0xA6A1..0xA6B8,0xA6C1..0xA6D8],
  'euc-kr'   => [0xA5C1..0xA5D8,0xA5E1..0xA5F8],
  'big5'     => [0xA344..0xA35B,0xA35C..0xA373],
  'shiftjis' => [0x839F..0x83B6,0x83BF..0x83D6],
  'utf8'     => [0x0391..0x03A1,0x03A3..0x03A9,0x03B1..0x03C1,0x03C3..0x03C9],
);
my @greek = qw(
  ALPHA BETA GAMMA DELTA EPSILON ZETA ETA
  THETA IOTA KAPPA LAMBDA MU NU XI OMICRON
  PI RHO SIGMA TAU UPSILON PHI CHI PSI OMEGA
  alpha beta gamma delta epsilon zeta eta
  theta iota kappa lambda mu nu xi omicron
  pi rho sigma tau upsilon phi chi psi omega
);

my %ideodigit = ( # cjk ideograph 'one' to 'ten'
  'euc-cn'   => [qw(d2bb b6fe c8fd cbc4 cee5 c1f9 c6df b0cb bec5 caae)],
  'euc-jp'   => [qw(b0ec c6f3 bbb0 bbcd b8de cfbb bcb7 c8ac b6e5 bdbd)],
  'euc-kr'   => [qw(ece9 eca3 dfb2 decc e7e9 d7bf f6d2 f8a2 cefa e4a8)],
  'big5'     => [qw(a440 a447 a454 a57c a4ad a4bb a443 a44b a445 a451)],
  'shiftjis' => [qw(88ea 93f1 8e4f 8e6c 8cdc 985a 8eb5 94aa 8be3 8f5c)],
  'utf8'     => [qw(4e00 4e8c 4e09 56db 4e94 516d 4e03 516b 4e5d 5341)],
);
my @ideodigit = qw(one two three four five six seven eight nine ten);

plan test => $n*@encodings + $n*@encodings*@greek + $n*@encodings*@ideodigit;

foreach my $enc (@encodings)
 {
  my $tab = Encode->getEncoding($enc);
  ok(1,defined($tab),"Could not load $enc");
  my $str = join('',map(chr($_),0x20..0x7E));
  my $uni = $tab->decode($str);
  my $cpy = $tab->encode($uni);
  ok($cpy,$str,"$enc mangled translating to Unicode and back");
 }

foreach my $enc (@encodings)
 {
  my $tab = Encode->getEncoding($enc);
  foreach my $gk (0..$#greek)
   {
     my $uni = unpack 'U', $tab->decode(pack 'n', $greek{$enc}[$gk]);
     ok($uni,$greek{'utf8'}[$gk],
       "$enc mangled translating to Unicode GREEK $greek[$gk]");
     my $cpy = unpack 'n',$tab->encode(pack 'U',$uni);
     ok($cpy,$greek{$enc}[$gk],
       "$enc mangled translating from Unicode GREEK $greek[$gk]");
   }
 }

foreach my $enc (@encodings)
 {
  my $tab = Encode->getEncoding($enc);
  foreach my $id (0..$#ideodigit)
   {
     my $uni = unpack 'U',$tab->decode(pack 'H*', $ideodigit{$enc}[$id]);
     ok($uni,hex($ideodigit{'utf8'}[$id]),
       "$enc mangled translating to Unicode CJK IDEOGRAPH $ideodigit[$id]");
     my $cpy = lc unpack 'H*', $tab->encode(pack 'U',$uni);
     ok($cpy,$ideodigit{$enc}[$id],
       "$enc mangled translating from Unicode CJK IDEOGRAPH $ideodigit[$id]");
   }
 }

