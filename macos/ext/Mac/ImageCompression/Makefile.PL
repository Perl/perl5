use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::ImageCompression),
	'VERSION_FROM'		=> 'ImageCompression.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
