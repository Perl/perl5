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

my $jis = '7bit-jis';
my $kr  = 'iso2022-kr';
my %esc_str;

$esc_str{$jis} = {qw(
  1b24422422242424262428242a1b2842
  3042304430463048304a
  1b284931323334355d1b2842
  ff71ff72ff73ff74ff75ff9d
  1b2442467c4b5c1b2842
  65e5672c
  3132331b244234413b7a1b28425065726c
  0031003200336f225b57005000650072006c
  546573740a1b24422546253925481b28420a
  0054006500730074000a30c630b930c8000a
)};

$esc_str{$kr} = {qw(
  1b2429430e2a22213e0f410d0a
  304200b10041000d000a
  1b2429430e3021332a34593673383639593b673e46405a0f0d0a
  ac00b098b2e4b77cb9c8bc14c0acc544c790000d000a
  1b2429434142430d0a
  004100420043000d000a
)};

my $num_esc = $n * keys(%esc_str);
foreach (values %esc_str){ $num_esc += $n * keys %$_ }

my $hz = 'HZ'; # HanZi

my @hz_txt = (
  "~~in GB.~{<:Ky2;S{#,NpJ)l6HK!#~}Bye.~~",
  "~~in GB.~{<:Ky2;S{#,~}~\cJ~{NpJ)l6HK!#~}Bye.~~",
  "~~in GB.~\cJ~{<:Ky2;S{#,NpJ)l6HK!#~}~\cJBye.~~",
);

my $hz_exp = '007e0069006e002000470042002e5df162404e0d6b32'
 . 'ff0c52ff65bd65bc4eba3002004200790065002e007e';

plan test => $n*@encodings + $n*@encodings*@greek
  + $n*@encodings*@ideodigit + $num_esc + $n + @hz_txt;

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

{
 sub to_unicode
  {
   my $enc = shift;
   return unpack('H*', pack 'n*', unpack 'U*',
   decode $enc, pack 'H*', join '', @_);
  }

 sub from_unicode
  {
   my $enc = shift;
   return unpack('H*', encode $enc,
   pack 'U*', unpack 'n*', pack 'H*', join '', @_);
  }

 foreach my $enc (sort keys %esc_str)
  {
   my $tab = Encode->getEncoding($enc);
   ok(1,defined($tab),"Could not load $enc");
   my %strings = %{ $esc_str{$enc} };
   foreach my $estr (sort keys %strings)
    {
     my $ustr = to_unicode($enc, $estr);
     ok($ustr, $strings{$estr},
	 "$enc mangled translating to Unicode");
     ok(from_unicode($enc, $ustr), $estr,
	 "$enc mangled translating from Unicode");
    }
   ok(to_unicode($enc, keys %strings), join('', values %strings),
   "$enc mangled translating to Unicode");
  }
}


{
 my $hz_to_unicode = sub
  {
   return unpack('H*', pack 'n*', unpack 'U*', decode $hz, shift);
  };

 my $hz_from_unicode = sub
  {
   return encode($hz, pack 'U*', unpack 'n*', pack 'H*', shift);
  };

 foreach my $enc ($hz)
  {
   my $tab = Encode->getEncoding($enc);
   ok(1,defined($tab),"Could not load $enc");

   ok(&$hz_from_unicode($hz_exp), $hz_txt[0],
       "$enc mangled translating from Unicode");

   foreach my $str (@hz_txt)
    {
     ok(&$hz_to_unicode($str), $hz_exp,
      "$enc mangled translating to Unicode");
    }
  }
}
