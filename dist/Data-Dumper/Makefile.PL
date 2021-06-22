use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    NAME          => 'Data::Dumper',
    VERSION_FROM  => 'Dumper.pm',
    ABSTRACT_FROM => 'Dumper.pm',
    $] <= 5.011000 ? ( INSTALLDIRS => 'perl' ) : (),
    ((grep { $_ eq 'PERL_CORE=1' } @ARGV) ? () : ('DEFINE' => '-DUSE_PPPORT_H')),
);
