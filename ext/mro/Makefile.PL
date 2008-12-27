use 5.010000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'mro',
    VERSION_FROM      => 'mro.pm', # finds $VERSION
    ABSTRACT_FROM     => 'mro.pm', # retrieve abstract from module
    MAN3PODS          => {},
    AUTHOR            => 'Brandon L. Black <blblack@gmail.com>');
