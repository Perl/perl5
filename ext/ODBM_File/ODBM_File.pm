package ODBM_File;

require TieHash;
require DynaLoader;
@ISA = qw(TieHash DynaLoader);

$VERSION = $VERSION = "1.00";

bootstrap ODBM_File;

1;

__END__
