package Encode::CN;
BEGIN {
    if (ord("A") == 193) {
	die "Encode::CN not supported on EBCDIC\n";
    }
}
our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Encode;
use Encode::CN::HZ;
use XSLoader;
XSLoader::load('Encode::CN',$VERSION);

# Relocated from Encode.pm

# use Encode::CN::2022_CN;

1;
__END__

=head1 NAME

Encode::CN - China-based Chinese Encodings

=head1 SYNOPSIS

    use Encode qw/encode decode/; 
    $euc_cn = encode("euc-cn", $utf8);   # loads Encode::CN implicitly
    $utf8   = decode("euc-cn", $euc_cn); # ditto

=head1 DESCRIPTION

This module implements China-based Chinese charset encodings.
Encodings supported are as follows.

  Canonical   Alias		Description
  --------------------------------------------------------------------
  euc-cn      /\beuc.*cn$/i	EUC (Extended Unix Character)
	      /\bcn.*euc$/i
              /\bGB[-_ ]?2312(?:\D.*$|$)/i (see below)
  gb2312-raw			The raw (low-bit) GB2312 character map
  gb12345-raw			Traditional chinese counterpart to 
				GB2312 (raw)
  iso-ir-165			GB2312 + GB6345 + GB8565 + additions
  cp936				Code Page 936, also known as GBK 
				(Extended GuoBiao)
  hz				7-bit escaped GB2312 encoding
  --------------------------------------------------------------------

To find how to use this module in detail, see L<Encode>.

=head1 NOTES

Due to size concerns, C<GB 18030> (an extension to C<GBK>) is distributed
separately on CPAN, under the name L<Encode::HanExtra>. That module
also contains extra Taiwan-based encodings.

=head1 BUGS

When you see C<charset=gb2312> on mails and web pages, they really
mean "euc-cn" encodings.  To fix that, gb2312 is aliased to euc-cn.  Use
gb2312-raw when you really mean it.

ASCII part (0x00-0x7f) is preserved for all encodings, even though it
conflicts with mappings by the Unicode Consortium.  See

L<http://www.debian.or.jp/~kubota/unicode-symbols.html.en>

to find why it is implemented that way.

=head1 SEE ALSO

L<Encode>,L<Encode::CJKguide>

=cut
