use ExtUtils::MakeMaker;

WriteMakefile(
	VERSION_FROM	=> "IO.pm",
	NAME      	=> "IO",
	OBJECT		=> '$(O_FILES)', 
);
