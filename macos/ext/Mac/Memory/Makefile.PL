use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Memory),
	'VERSION_FROM'		=> 'Memory.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
