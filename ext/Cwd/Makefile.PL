# core-only Makefile.PL
use ExtUtils::MakeMaker;
use File::Spec;
my $up = File::Spec->updir();

WriteMakefile(
    NAME    => 'Cwd',
    VERSION_FROM => '../../lib/Cwd.pm',
    'DEFINE' => '-DNO_PPPORT_H',
    XS_VERSION => eval MM->parse_version(File::Spec->catfile($up, $up, 'lib', 'Cwd.pm')),
);
