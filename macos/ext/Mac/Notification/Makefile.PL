use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Notification),
	'VERSION_FROM'		=> 'Notification.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> 'typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
