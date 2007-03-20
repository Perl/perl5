use ExtUtils::MakeMaker;
WriteMakefile(
    NAME    => 'Cwd',
    VERSION_FROM => '../../lib/Cwd.pm',
    (
        (grep { $_ eq 'PERL_CORE=1' } @ARGV)
            ? ()
            : ('DEFINE' => '-DUSE_PPPORT_H')
    ),
);
