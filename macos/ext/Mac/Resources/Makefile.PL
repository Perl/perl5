use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Resources),
	'VERSION_FROM'		=> 'Resources.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
