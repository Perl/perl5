package NDBM_File;

require TieHash;
require DynaLoader;
@ISA = qw(TieHash DynaLoader);

bootstrap NDBM_File;

1;

__END__
