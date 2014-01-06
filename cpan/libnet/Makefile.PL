use strict;
use ExtUtils::MakeMaker;

WriteMakefile (
    NAME            => 'Net',
    DISTNAME        => 'libnet',
    VERSION         => '1.24', # finds $VERSION
    AUTHOR          => 'Graham Barr <gbarr@pobox.com>',
    ABSTRACT        => 'Collection of Network protocol modules',
);
