package Encode::EBCDIC;
use Encode;
our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use XSLoader;
XSLoader::load('Encode::EBCDIC',$VERSION);

1;
__END__

=head1 NAME

Encode::EBCDIC - EBCDIC Encodings

=head1 SYNOPSIS

    use Encode qw/encode decode/; 
    $posix_bc  = encode("posix-bc", $utf8); # loads Encode::EBCDIC implicitly
    $utf8 = decode("", $posix_bc);          # ditto

=head1 ABSTRACT

This module implements various EBCDIC-Based encodings.  Encodings
supported are as follows.   

  Canonical   Alias		Description
  --------------------------------------------------------------------
  cp1047
  cp37
  posix-bc

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 SEE ALSO

L<Encode>, L<perlebcdic>

=cut
