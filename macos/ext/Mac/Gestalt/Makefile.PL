use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Gestalt),
	'VERSION_FROM'		=> 'Gestalt.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
