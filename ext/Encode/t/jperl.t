#
# $Id: jperl.t,v 1.20 2002/04/04 19:50:52 dankogai Exp dankogai $
#
# This script is written in euc-jp

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
	print "1..0 # Skip: EBCDIC\n";
	exit 0;
    }
    $| = 1;
}

use strict;
use Test::More tests => 15;
my $Debug = shift;

no encoding; # ensure
my $Enamae = "\xbe\xae\xbb\xf4\x20\xc3\xc6"; # euc-jp, with \x escapes
use encoding "euc-jp";

my $Namae  = "¾®»ô ÃÆ";   # in Japanese, in euc-jp
my $Name   = "Dan Kogai"; # in English
# euc-jp in \x format but after the pragma.  But this one will be converted!
my $Ynamae = "\xbe\xae\xbb\xf4\x20\xc3\xc6"; 


my $str = $Namae; $str =~ s/¾®»ô ÃÆ/Dan Kogai/o;
is($str, $Name, q{regex});
$str = $Namae; $str =~ s/$Namae/Dan Kogai/o;
is($str, $Name, q{regex - with variable});
is(length($Namae), 4, q{utf8:length});
{
    use bytes;
    # converted to UTF-8 so 3*3+1
    is(length($Namae),   10, q{bytes:length}); 
    # 
    is(length($Enamae),   7, q{euc:length}); # 2*3+1
    is ($Namae, $Ynamae,     q{literal conversions});
    isnt($Enamae, $Ynamae,   q{before and after}); 
    is($Enamae, Encode::encode('euc-jp', $Namae)); 
}
# let's test the scope as well.  Must be in utf8 realm
is(length($Namae), 4, q{utf8:length});

{
    no encoding;
    ok(! defined(${^ENCODING}), q{no encoding;});
}
# should've been isnt() but no scoping is suported -- yet
ok(! defined(${^ENCODING}), q{not scoped yet});
{
    # now let's try some real black magic!
    local(${^ENCODING}) = Encode::find_encoding("euc-jp");
    my $str = "\xbe\xae\xbb\xf4\x20\xc3\xc6";
   is (length($str), 4, q{black magic:length});
   is ($str, $Enamae,   q{black magic:eq});
}
ok(! defined(${^ENCODING}), q{out of black magic});
use bytes;
is (length($Namae), 10);
1;
__END__


