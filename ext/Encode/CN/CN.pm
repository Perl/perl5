package Encode::CN;
our $VERSION = do { my @r = (q$Revision: 0.90 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use Encode;
use Encode::CN::HZ;
use XSLoader;
XSLoader::load('Encode::CN',$VERSION);

1;
__END__
=head1 NAME

Encode::CN - China-based Chinese Encodings

=head1 SYNOPSIS

    use Encode 'encode'; 
    $euc_cn = encode("euc-cn", $utf8);   # loads Encode::CN implicitly
    $utf8   = decode("euc-cn", $euc_cn); # ditto

=head1 DESCRIPTION

This module implements China-based Chinese charset encodings.
Encodings supported are as follows.

  euc-cn	EUC (Extended Unix Character)
  gb2312	The raw (low-bit) GB2312 character map
  gb12345	Traditional chinese counterpart to GB2312 (raw)
  iso-ir-165	GB2312 + GB6345 + GB8565 + additions
  cp936		Code Page 936, also known as GBK (Extended GuoBiao)
  hz		7-bit escaped GB2312 encoding

To find how to use this module in detail, see L<Encode>.

=head1 NOTES

Due to size concerns, C<GB 18030> (an extension to C<GBK>) is distributed
separately on CPAN, under the name L<Encode::HanExtra>. That module
also contains extra Taiwan-based encodings.

=head1 BUGS

ASCII part (0x00-0x7f) is preserved for all encodings, even though it
conflicts with mappings by the Unicode Consortium.  See

F<http://www.debian.or.jp/~kubota/unicode-symbols.html.en>

to find why it is implemented that way.

=head1 SEE ALSO

L<Encode>

=cut
