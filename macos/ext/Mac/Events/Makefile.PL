use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Events),
	'VERSION_FROM'		=> 'Events.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
