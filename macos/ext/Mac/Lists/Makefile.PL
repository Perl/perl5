use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Lists),
	'VERSION_FROM'		=> 'Lists.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap ::Controls:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
