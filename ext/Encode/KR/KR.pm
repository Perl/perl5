package Encode::KR;
our $VERSION = '0.02';

use Encode;
use XSLoader;
XSLoader::load('Encode::KR',$VERSION);

1;
__END__
=head1 NAME

Encode::KR - Korean Encodings

=head1 SYNOPSIS

    use Encode::CN;
    $euc_kr = encode("euc-kr", $utf8);
    $utf8   = encode("euc-kr", $euc_kr);

=head1 DESCRIPTION

This module implements Korean charset encodings.  Encodings supported
are as follows.

  euc-kr	EUC (Extended Unix Character)
  ksc5601	Korean standard code set
  cp949		Code Page 949 (EUC-KR + Unified Hangul Code)
  
To find how to use this module in detail, see L<Encode>.

=head1 BUGS

The C<Johab> (two-byte combination code) encoding is not supported.

ASCII part (0x00-0x7f) is preserved for all encodings, even though it
conflicts with mappings by the Unicode Consortium.  See

F<http://www.debian.or.jp/~kubota/unicode-symbols.html.en>

to find why it is implemented that way.

=head1 SEE ALSO

L<Encode>

=cut
