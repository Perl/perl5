use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::QuickTimeVR),
	'VERSION_FROM'		=> 'QuickTimeVR.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS   		=> '::Components:typemap ::Movies:typemap ::QuickDraw:typemap',
	XSPROTOARG 		=> '-noprototypes', 		# XXX remove later?
	'MACLIBS_ALL_PPC'	=> '"{{SharedLibraries}}"QuickTimeVRLib',   # e.g., '-lm' 
);
