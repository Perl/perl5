package Encode::Symbol;
use Encode;
our $VERSION = do { my @r = (q$Revision: 0.96 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use XSLoader;
XSLoader::load('Encode::Symbol',$VERSION);

1;
__END__
=head1 NAME

Encode::Symbol - EBCDIC Encodings

=head1 SYNOPSIS

    use Encode qw/encode decode/; 
    $symbol  = encode("symbol", $utf8); # loads Encode::Symbol implicitly
    $utf8 = decode("", $symbol);        # ditto

=head1 ABSTRACT

This module implements symbol and dingbats encodings.  Encodings
supported are as follows.   

  Canonical   Alias		Description
  --------------------------------------------------------------------
  symbol
  dingbats

=head1 DESCRIPTION

To find how to use this module in detail, see L<Encode>.

=head1 SEE ALSO

L<Encode>

=cut
