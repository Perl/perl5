package PerlIO::encoding;
our $VERSION = '0.03';
use XSLoader ();
use Encode (); # Load but do not import anything.
our $check;
XSLoader::load 'PerlIO::encoding';
1;
__END__

=head1 NAME

PerlIO::encoding - encoding layer

=head1 SYNOPSIS

  open($f, "<:encoding(foo)", "infoo");
  open($f, ">:encoding(bar)", "outbar");

  use Encode;
  $PerlIO::encoding::check = Encode::FB_PERLQQ();

=head1 DESCRIPTION

Open a filehandle with a transparent encoding filter.

On input, convert the bytes expected to be in the specified
character set and encoding to Perl string data (Unicode and
Perl's internal Unicode encoding, UTF-8).  On output, convert
Perl string data into the specified character set and encoding.

When the layer is pushed the current value of C<$PerlIO::encoding::check>
is saved and used as the check argument when calling the Encodings
encode and decode.

=head1 SEE ALSO

L<open>, L<Encode>, L<perlfunc/binmode>, L<perluniintro>

=cut


