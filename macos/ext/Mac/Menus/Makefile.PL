use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Menus),
	'VERSION_FROM'		=> 'Menus.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
