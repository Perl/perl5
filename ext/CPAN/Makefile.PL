use strict;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME            => 'CPAN',
    VERSION_FROM    => 'lib/CPAN.pm', # finds $VERSION
    EXE_FILES       => ['scripts/cpan'],
    AUTHOR          => 'Andreas Koenig <andreas.koenig.gmwojprw@franz.ak.mind.de>',
    ABSTRACT_FROM   => 'lib/CPAN.pm',
);
