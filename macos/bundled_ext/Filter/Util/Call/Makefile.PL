use ExtUtils::MakeMaker;

WriteMakefile(
	NAME      	=> 'Filter::Util::Call',
	DEFINE		=> '-D_NOT_CORE',
	VERSION_FROM   	=> 'Call.pm',
);
