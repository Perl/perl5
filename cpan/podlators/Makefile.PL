use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Pod',
    DISTNAME        => 'podlators',
    VERSION_FROM    => 'lib/Pod/Man.pm',
    EXE_FILES       => [ 'bin/pod2man', 'bin/pod2text' ],
    AUTHOR          => 'Russ Allbery (rra@stanford.edu)',
    ABSTRACT        => 'Convert POD data to various other formats'
);
