use ExtUtils::MakeMaker;

WriteMakefile(
    NAME		=> 'Sys::Syslog',
    VERSION_FROM	=> 'Syslog.pm', 
    XSPROTOARG          => '-noprototypes',
);
