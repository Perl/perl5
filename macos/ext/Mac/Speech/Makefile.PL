use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Speech),
	'VERSION_FROM'		=> 'Speech.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG 		=> '-noprototypes', 		# XXX remove later?
	MACLIBS_SHARED		=> '"{{SharedLibraries}}"SpeechLib',   # e.g., '-lm' 
);
