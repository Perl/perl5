package Encode::XS;
use strict;
our $VERSION = do { my @r = (q$Revision: 0.92 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

use base 'Encode::Encoding';
1;
__END__

