use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Files),
	'VERSION_FROM'		=> 'Files.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
