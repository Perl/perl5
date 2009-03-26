use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Sys::Hostname',
    VERSION_FROM        => 'Hostname.pm', 
    XSPROTOARG          => '-noprototypes',
);
