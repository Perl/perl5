use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::QDOffscreen),
	'VERSION_FROM'		=> 'QDOffscreen.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
