package Encode::XS;
use strict;
our $VERSION = do { my @r = (q$Revision: 1.0 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use base 'Encode::Encoding';
1;
__END__

=head1 NAME

Encode::XS -- for internal use only

=cut
