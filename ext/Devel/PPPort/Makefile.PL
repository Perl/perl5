
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Devel::PPPort",
	DISTNAME => "Devel-PPPort",
	VERSION_FROM => 'PPPort.pm',
	
	#PM => {'PPPort.pm' => '$(INST_LIBDIR)/PPPort.pm'}, 
	XSPROTOARG => '-noprototypes',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" }
);
