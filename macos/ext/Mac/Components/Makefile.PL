use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Components),
	'VERSION_FROM'		=> 'Components.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
