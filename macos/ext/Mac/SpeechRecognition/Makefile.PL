use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::SpeechRecognition),
	'VERSION_FROM'		=> 'SpeechRecognition.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG 		=> '-noprototypes', 		# XXX remove later?
	MACLIBS_SHARED		=> '"{{SharedLibraries}}"SpeechRecognitionLib',   # e.g., '-lm' 
);
