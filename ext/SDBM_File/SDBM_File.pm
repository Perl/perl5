package SDBM_File;

use strict;
use vars qw($VERSION @ISA);

require Tie::Hash;
require DynaLoader;

@ISA = qw(Tie::Hash DynaLoader);

$VERSION = "1.00" ;

bootstrap SDBM_File $VERSION;

1;

__END__
