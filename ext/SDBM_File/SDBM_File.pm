package SDBM_File;

require TieHash;
require DynaLoader;
@ISA = qw(TieHash DynaLoader);

bootstrap SDBM_File;

1;

__END__
