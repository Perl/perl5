package ODBM_File;

require TieHash;
require DynaLoader;
@ISA = qw(TieHash DynaLoader);

bootstrap ODBM_File;

1;

__END__
