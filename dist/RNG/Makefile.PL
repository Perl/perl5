use 5.008;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'RNG',
    VERSION_FROM => 'lib/RNG.pm',
    ABSTRACT_FROM => 'lib/RNG.pm',
    AUTHOR       => 'Perl Porters',
    LICENSE      => 'perl',
    XS           => { 'RNG.xs' => 'RNG.c' },
    clean        => { FILES => 'RNG.c' },
);
