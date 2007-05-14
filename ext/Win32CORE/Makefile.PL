use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Win32CORE',
    'DEFINE'		=> '-DPERLDLL -DPERL_CORE',
    'VERSION_FROM'	=> 'Win32CORE.pm',
);
