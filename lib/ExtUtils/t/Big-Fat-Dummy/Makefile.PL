use ExtUtils::MakeMaker;

printf "Current package is: %s\n", __PACKAGE__;

WriteMakefile(
    NAME          => 'Big::Fat::Dummy',
    VERSION_FROM  => 'lib/Big/Fat/Dummy.pm',
    PREREQ_PM     => {},
);
