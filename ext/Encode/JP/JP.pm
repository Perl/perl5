package Encode::JP;
BEGIN {
    if (ord("A") == 193) {
	die "Encode::JP not supported on EBCDIC\n";
    }
}
use Encode;
our $VERSION = do { my @r = (q$Revision: 0.96 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use XSLoader;
XSLoader::load('Encode::JP',$VERSION);

use Encode::JP::JIS;
use Encode::JP::ISO_2022_JP;

1;
__END__
=head1 NAME

Encode::JP - Japanese Encodings

=head1 SYNOPSIS

    use Encode qw/encode decode/; 
    $euc_jp = encode("euc-jp", $utf8);   # loads Encode::JP implicitly
    $utf8   = decode("euc-jp", $euc_jp); # ditto

=head1 ABSTRACT

This module implements Japanese charset encodings.  Encodings
supported are as follows.

  Canonical   Alias		Description
  --------------------------------------------------------------------
  euc-jp      /euc.*jp$/i	EUC (Extended Unix Character)
              /jp.*euc/i   
	      /ujis$/i
  shiftjis    /shift.*jis$/i	Shift JIS (aka MS Kanji)
	      /sjis$/i
  7bit-jis    /^jis$/i		7bit JIS
  iso-2022-jp			ISO-2022-JP 
				(7bit JIS with all Halfwidth Kana 
				 converted to Fullwidth)
  macjapan      Mac Japan	(Shift JIS + Apple vendor mappings)
  cp932         Code Page 932	(Shift JIS + MS/IBM vendor mappings)
  --------------------------------------------------------------------

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 BUGS

ASCII part (0x00-0x7f) is preserved for all encodings, even though it
conflicts with mappings by the Unicode Consortium.  See

F<http://www.debian.or.jp/~kubota/unicode-symbols.html.en>

to find why it is implemented that way.

=head1 SEE ALSO

L<Encode>

=cut
