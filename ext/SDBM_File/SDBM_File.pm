package SDBM_File;

require TieHash;
require DynaLoader;
@ISA = qw(TieHash DynaLoader);

$VERSION = $VERSION = "1.00" ;

bootstrap SDBM_File;

1;

__END__
