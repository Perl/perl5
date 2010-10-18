use strict;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME            => 'Pod',
    DISTNAME        => 'podlators',
    VERSION_FROM    => 'VERSION', # finds $VERSION
    EXE_FILES       => [ 'scripts/pod2man', 'scripts/pod2text' ],
    INSTALLDIRS     => ( $] >= 5.006 ? 'perl' : 'site' ),
    AUTHOR          => 'Russ Allbery (rra@stanford.edu)',
    ABSTRACT        => 'Convert POD data to various other formats'
);
