package Encode::TW;
our $VERSION = '0.02';

use Encode;
use XSLoader;
XSLoader::load('Encode::TW',$VERSION);

local $@;
eval "use Encode::HanExtra"; # load extra encodings if they exist

1;
__END__
=head1 NAME

Encode::TW - Taiwan-based Chinese Encodings

=head1 SYNOPSIS

    use Encode::CN;
    $big5 = encode("big5", $utf8);
    $utf8 = encode("big5", $big5);

=head1 DESCRIPTION

This module implements Taiwan-based Chinese charset encodings.
Encodings supported are as follows.

  big5		The original Big5 encoding
  big5-hkscs	Big5 plus Cantonese characters in Hong Kong
  cp950		Code Page 950 (Big5 + Microsoft vendor mappings)
  
To find how to use this module in detail, see L<Encode>.

=head1 NOTES

Due to size concerns, C<EUC-TW> (Extended Unix Character) and C<BIG5PLUS>
(CMEX's Big5+) are distributed separately on CPAN, under the name
L<Encode::HanExtra>. That module also contains extra China-based encodings.

This module will automatically load L<Encode::HanExtra> if you have it on
your machine.

=head1 BUGS

The C<CNS11643> encoding files are not complete (only the first two planes,
C<11643-1> and C<11643-2>, exist in the distribution). For common CNS11643
manipulation, please use C<EUC-TW> in L<Encode::HanExtra>, which contains
plane 1-7.

ASCII part (0x00-0x7f) is preserved for all encodings, even though it
conflicts with mappings by the Unicode Consortium.  See

F<http://www.debian.or.jp/~kubota/unicode-symbols.html.en>

to find why it is implemented that way.

=head1 SEE ALSO

L<Encode>

=cut
