# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 22 };
use Unicode::Collate;
ok(1); # If we made it this far, we're ok.

#########################

my $UCA = Unicode::Collate->new(
  table => 'keys.txt',
  normalization => undef,
);

ok(ref $UCA, "Unicode::Collate");

ok(
  join(':', $UCA->sort( 
    qw/ lib strict Carp ExtUtils CGI Time warnings Math overload Pod CPAN /
  ) ),
  join(':',
    qw/ Carp CGI CPAN ExtUtils lib Math overload Pod strict Time warnings /
  ),
);

my $A_acute = pack('U', 0x00C1);
my $acute   = pack('U', 0x0301);

ok($UCA->cmp("A$acute", $A_acute), -1);

ok($UCA->cmp("", ""), 0);
ok($UCA->cmp("", "perl"), -1);

eval "use Unicode::Normalize";

if(!$@){
  my $NFD = Unicode::Collate->new(
    table => 'keys.txt',
  );
  ok($NFD->cmp("A$acute", $A_acute), 0);
}
else{
  ok(1);
}

my $tr = Unicode::Collate->new(
  table => 'keys.txt',
  normalization => undef,
  ignoreName => qr/^(?:HANGUL|HIRAGANA|KATAKANA|BOPOMOFO)$/,
  entry => <<'ENTRIES',
0063 0068 ; [.0893.0020.0002.0063]  # "ch" in traditional Spanish
0043 0068 ; [.0893.0020.0008.0043]  # "Ch" in traditional Spanish
ENTRIES
);

ok(
  join(':', $tr->sort( 
    qw/ acha aca ada acia acka /
  ) ),
  join(':',
    qw/ aca acia acka acha ada /
  ),
);

ok(
  join(':', $UCA->sort( 
    qw/ acha aca ada acia acka /
  ) ),
  join(':',
    qw/ aca acha acia acka ada /
  ),
);

my $old_level = $UCA->{level};
my $hiragana = "\x{3042}\x{3044}";
my $katakana = "\x{30A2}\x{30A4}";

$UCA->{level} = 2;

ok( $UCA->cmp("ABC","abc"), 0);
ok( $UCA->cmp($hiragana, $katakana), 0);

$UCA->{level} = $old_level;

$UCA->{katakana_before_hiragana} = 1;

ok( $UCA->cmp("abc", "ABC"), -1);
ok( $UCA->cmp($hiragana, $katakana), 1);

$UCA->{upper_before_lower} = 1;

ok( $UCA->cmp("abc", "ABC"), 1);
ok( $UCA->cmp($hiragana, $katakana), 1);

$UCA->{katakana_before_hiragana} = 0;

ok( $UCA->cmp("abc", "ABC"), 1);
ok( $UCA->cmp($hiragana, $katakana), -1);

$UCA->{upper_before_lower} = 0;

ok( $UCA->cmp("abc", "ABC"), -1);
ok( $UCA->cmp($hiragana, $katakana), -1);

my $ign = Unicode::Collate->new(
  table => 'keys.txt',
  normalization => undef,
  ignoreChar => qr/^[ae]$/,
);

ok( $ign->cmp("element","lament"), 0);

$UCA->{level} = 2;

my $orig = "This is a Perl book.";
my $str;
my $sub = "PERL";
my $rep = "camel";
my $ret = "This is a camel book.";

$str = $orig;
if(my @tmp = $UCA->index($str, $sub)){
  substr($str, $tmp[0], $tmp[1], $rep);
}

ok($str, $ret);

$UCA->{level} = $old_level;

$str = $orig;
if(my @tmp = $UCA->index($str, $sub)){
  substr($str, $tmp[0], $tmp[1], $rep);
}

ok($str, $orig);

