use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Controls),
	'VERSION_FROM'		=> 'Controls.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
