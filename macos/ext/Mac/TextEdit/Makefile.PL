use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::TextEdit),
	'VERSION_FROM'		=> 'TextEdit.pm',
	'LINKTYPE'		=> 'static dynamic',
	TYPEMAPS		=> '::QuickDraw:typemap',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
);
