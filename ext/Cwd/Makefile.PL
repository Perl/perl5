# core-only Makefile.PL
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME    => 'Cwd',
    VERSION_FROM => 'Cwd.pm',
    'DEFINE' => '-DNO_PPPORT_H',
);
