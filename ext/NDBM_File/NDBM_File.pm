package NDBM_File;

require TieHash;
require DynaLoader;
@ISA = qw(TieHash DynaLoader);

$VERSION = $VERSION = "1.00";

bootstrap NDBM_File;

1;

__END__
