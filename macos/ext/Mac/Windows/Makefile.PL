use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Windows),
	'VERSION_FROM'		=> 'Windows.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap ::Controls:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
