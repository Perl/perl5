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

   open($fh, "<",  \$scalar);
   open($fh, ">",  \$scalar);
   open($fh, ">>", \$scalar);

   open($fh, "<...",  \$scalar); # for example open($fh, "<:crlf", \$scalar);
   open($fh, ">...",  \$scalar); # for example open($fh, ">:utf8", \$scalar);
   open($fh, ">>..",  \$scalar);

=head1 DESCRIPTION

Open scalars for "in memory" input and output.  The scalars will
behave as if they were files.

=cut


