use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Movies),
	'VERSION_FROM'		=> 'Movies.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS  		=> '::Components:typemap ::Events:typemap ::QuickDraw:typemap ::QDOffscreen:typemap ::Menus:typemap',
	XSPROTOARG 		=> '-noprototypes', 		# XXX remove later?
	MACLIBS_SHARED		=> '"{{SharedLibraries}}"QuickTimeLib',   # e.g., '-lm' 
);
