use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::InternetConfig),
	'VERSION_FROM'		=> 'InternetConfig.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
	'MACLIBS_SHARED'	=> '$(PERL_SRC):IC:InternetConfigLib',
	'OBJECT'		=> 'InternetConfig.c',
	'INC'			=> '-i $(PERL_SRC):IC:'
);
