use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::QuickDraw),
	'VERSION_FROM'		=> 'QuickDraw.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
