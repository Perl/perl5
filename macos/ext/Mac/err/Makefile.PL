use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME' 		=> q(Mac::err),
	'VERSION_FROM'	=> 'err.pm',
    	'LINKTYPE'	=> 'static dynamic',
);
