# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

use Test;
BEGIN { plan tests => 50 };
use Unicode::Collate;
ok(1); # If we made it this far, we're ok.

#########################

my $Collator = Unicode::Collate->new(
  table => 'keys.txt',
  normalization => undef,
);

ok(ref $Collator, "Unicode::Collate");

ok(
  join(':', $Collator->sort( 
    qw/ lib strict Carp ExtUtils CGI Time warnings Math overload Pod CPAN /
  ) ),
  join(':',
    qw/ Carp CGI CPAN ExtUtils lib Math overload Pod strict Time warnings /
  ),
);

my $A_acute = pack('U', 0x00C1);
my $acute   = pack('U', 0x0301);

ok($Collator->cmp("A$acute", $A_acute), -1);

ok($Collator->cmp("", ""), 0);
ok(! $Collator->ne("", "") );
ok(  $Collator->eq("", "") );

ok($Collator->cmp("", "perl"), -1);

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
00DF ; [.09F3.0154.0004.00DF] [.09F3.0020.0004.00DF] # eszet in Germany
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
  join(':', $Collator->sort( 
    qw/ acha aca ada acia acka /
  ) ),
  join(':',
    qw/ aca acha acia acka ada /
  ),
);

my $old_level = $Collator->{level};
my $hiragana = "\x{3042}\x{3044}";
my $katakana = "\x{30A2}\x{30A4}";

$Collator->{level} = 2;

ok( $Collator->cmp("ABC","abc"), 0);
ok( $Collator->eq("ABC","abc") );
ok( $Collator->le("ABC","abc") );
ok( $Collator->cmp($hiragana, $katakana), 0);
ok( $Collator->eq($hiragana, $katakana) );
ok( $Collator->ge($hiragana, $katakana) );

# hangul
ok( $Collator->eq("a\x{AC00}b", "a\x{1100}\x{1161}b") );
ok( $Collator->eq("a\x{AE00}b", "a\x{1100}\x{1173}\x{11AF}b") );
ok( $Collator->gt("a\x{AE00}b", "a\x{1100}\x{1173}b\x{11AF}") );
ok( $Collator->lt("a\x{AC00}b", "a\x{AE00}b") );
ok( $Collator->gt("a\x{D7A3}b", "a\x{C544}b") );
ok( $Collator->lt("a\x{C544}b", "a\x{30A2}b") ); # hangul < hiragana

$Collator->{level} = $old_level;

$Collator->{katakana_before_hiragana} = 1;

ok( $Collator->cmp("abc", "ABC"), -1);
ok( $Collator->ne("abc", "ABC") );
ok( $Collator->lt("abc", "ABC") );
ok( $Collator->le("abc", "ABC") );
ok( $Collator->cmp($hiragana, $katakana), 1);
ok( $Collator->ne($hiragana, $katakana) );
ok( $Collator->gt($hiragana, $katakana) );
ok( $Collator->ge($hiragana, $katakana) );

$Collator->{upper_before_lower} = 1;

ok( $Collator->cmp("abc", "ABC"), 1);
ok( $Collator->ge("abc", "ABC"), 1);
ok( $Collator->gt("abc", "ABC"), 1);
ok( $Collator->cmp($hiragana, $katakana), 1);
ok( $Collator->ge($hiragana, $katakana), 1);
ok( $Collator->gt($hiragana, $katakana), 1);

$Collator->{katakana_before_hiragana} = 0;

ok( $Collator->cmp("abc", "ABC"), 1);
ok( $Collator->cmp($hiragana, $katakana), -1);

$Collator->{upper_before_lower} = 0;

ok( $Collator->cmp("abc", "ABC"), -1);
ok( $Collator->le("abc", "ABC") );
ok( $Collator->cmp($hiragana, $katakana), -1);
ok( $Collator->lt($hiragana, $katakana) );

my $ign = Unicode::Collate->new(
  table => 'keys.txt',
  normalization => undef,
  ignoreChar => qr/^[ae]$/,
);

ok( $ign->cmp("element","lament"), 0);

$Collator->{level} = 2;

my $str;

my $orig = "This is a Perl book.";
my $sub = "PERL";
my $rep = "camel";
my $ret = "This is a camel book.";

$str = $orig;
if(my($pos,$len) = $Collator->index($str, $sub)){
  substr($str, $pos, $len, $rep);
}

ok($str, $ret);

$Collator->{level} = $old_level;

$str = $orig;
if(my($pos,$len) = $Collator->index($str, $sub)){
  substr($str, $pos, $len, $rep);
}

ok($str, $orig);

$tr->{level} = 1;

$str = "Ich mu\x{00DF} studieren.";
$sub = "m\x{00FC}ss";
my $match = undef;
if(my($pos, $len) = $tr->index($str, $sub)){
    $match = substr($str, $pos, $len);
}
ok($match, "mu\x{00DF}");

$tr->{level} = $old_level;

$str = "Ich mu\x{00DF} studieren.";
$sub = "m\x{00FC}ss";
$match = undef;
if(my($pos, $len) = $tr->index($str, $sub)){
    $match = substr($str, $pos, $len);
}
ok($match, undef);

$match = undef;
if(my($pos,$len) = $Collator->index("", "")){
    $match = substr("", $pos, $len);
}
ok($match, "");

$match = undef;
if(my($pos,$len) = $Collator->index("", "abc")){
    $match = substr("", $pos, $len);
}
ok($match, undef);

