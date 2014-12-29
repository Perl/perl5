use strict; use warnings;
use ExtUtils::MakeMaker;

my $define = '-DSDBM -DDUFF';
# no -DMSDOS because MSDOS and WIN32 treated same in code
$define .= ' -DWIN32 -DPERL_STATIC_SYMS' if $^O eq 'MSWin32';

WriteMakefile(
    NAME      => 'SDBM_File',
    VERSION_FROM => 'SDBM_File.pm',
    DEFINE    => $define,
    INC       => '-I$(PERL_INC)', # force PERL_INC dir ahead of system -I's
    OBJECT    => '$(O_FILES)',
    clean     => {'FILES' => 'dbu dbd dba dbe x-dbu *.dir *.pag'},
    H         => [qw(tune.h sdbm.h pair.h $(PERL_INC)/config.h)],
    C         => [qw(SDBM_File.c sdbm.c pair.c hash.c)],
);
