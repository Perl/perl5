package PerlIO::encoding;
our $VERSION = '0.01';
use XSLoader ();
use Encode;
XSLoader::load 'PerlIO::encoding';
1;
__END__

=head1 NAME

PerlIO::encoding - encoding layer

=head1 SYNOPSIS

   open($fh,"<...",\$scalar);

=head1 DESCRIPTION

=cut


