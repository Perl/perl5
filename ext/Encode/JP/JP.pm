package Encode::JP;
BEGIN {
    if (ord("A") == 193) {
	die "Encode::JP not supported on EBCDIC\n";
    }
}
use Encode;
our $VERSION = do { my @r = (q$Revision: 0.98 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use XSLoader;
XSLoader::load('Encode::JP',$VERSION);

use Encode::JP::JIS;
use Encode::JP::ISO_2022_JP;
use Encode::JP::ISO_2022_JP_1;

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
  iso-2022-jp-1			ISO-2022-JP-1
                                (ISO-2022-JP with JIS X 0212-1990
				 support. See below)
  macjapan      Mac Japan	(Shift JIS + Apple vendor mappings)
  cp932         Code Page 932	(Shift JIS + MS/IBM vendor mappings)
  --------------------------------------------------------------------

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 Note on ISO-2022-JP(-1)?

ISO-2022-JP-1 (RFC2237) is a superset of ISO-2022-JP (RFC1468) which
adds support for JIS X 0212-1990.  That means you can use the same
code to decode to utf8 but not vice versa.

  $utf8 = decode('iso-2022-jp-1', $stream);
  $utf8 = decode('iso-2022-jp',   $stream);

Yields the same result but

  $with_0212 = encode('iso-2022-jp-1', $utf8);

is now different from

  $without_0212 = encode('iso-2022-jp', $utf8 );

In the latter case, characters that map to 0212 are at first converted
to U+3013 (0xA2AE in EUC-JP; a white square also known as 'Tofu') then
fed to decoding engine.  U+FFFD is not used to preserve text layout as
much as possible.

=head1 BUGS

ASCII part (0x00-0x7f) is preserved for all encodings, even though it
conflicts with mappings by the Unicode Consortium.  See

L<http://www.debian.or.jp/~kubota/unicode-symbols.html.en>

to find why it is implemented that way.

=head1 SEE ALSO

L<Encode>

=cut
