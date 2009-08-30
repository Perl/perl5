use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => 'Safe',
    VERSION_FROM => 'Safe.pm',
    INSTALLDIRS => 'perl',
    INST_LIB => '$(INST_ARCHLIB)',
);

