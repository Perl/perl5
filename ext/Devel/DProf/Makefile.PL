use ExtUtils::MakeMaker;
WriteMakefile(
	'NAME'		=> 'Devel::DProf',
	'VERSION'	=> 'Apr5,1995',
	'clean'		=> {'FILES' => "tmon.out"},
	'EXE_FILES'	=> ['dprofpp'],

);
