use ExtUtils::MakeMaker;

WriteMakefile(
	NAME			=> q(Mac::Processes),
	'VERSION_FROM'		=> 'Processes.pm',
	'LINKTYPE'		=> 'static dynamic',
	XSPROTOARG		=> '-noprototypes', 		# XXX remove later?
	'LIBS'			=> ['"{{MW68KLibraries}}MathLibCFM68K (4i_8d).Lib" "{{MWPPCLibraries}}"MathLib'],   # e.g., '-lm' 
);
