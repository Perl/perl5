use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::StandardFile),
	'VERSION_FROM'		=> 'StandardFile.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap ::Events:typemap ::Files:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
