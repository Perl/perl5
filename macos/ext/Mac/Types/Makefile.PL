use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Types),
	'VERSION_FROM'		=> 'Types.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
