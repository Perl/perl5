use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Fonts),
	'VERSION_FROM'		=> 'Fonts.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
