use ExtUtils::MakeMaker;
use Config qw(%Config);

WriteMakefile(
	VERSION_FROM	=> "IO.pm",
	NAME      	=> "IO",
	OBJECT		=> '$(O_FILES)', 
	DEFINE		=> $define,
	MAN3PODS	=> {},		# Pods will be built by installman.
);
