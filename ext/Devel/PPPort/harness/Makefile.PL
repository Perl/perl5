
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Devel::Harness",
	VERSION_FROM => '../PPPort.pm',
	
	
	XSPROTOARG => '-noprototypes',
	#PM => {'Harness.pm' => '$(INST_LIBDIR)/Harness.pm'},
	#XS => {'Harness.xs' => 'Harness.c'},
	OBJECT => 'Harness$(OBJ_EXT) module2$(OBJ_EXT) module3$(OBJ_EXT)',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },

);

sub MY::postamble {<<'EOM'};

sweep:
	$(RM_F) pm_to_blib Harness.c Harness$(OBJ_EXT) module2$(OBJ_EXT) module3$(OBJ_EXT) ppport.h
	$(RM_RF) ./blib

Harness.c module2.c module3.c :	ppport.h

ppport.h: ../PPPort.pm
	$(PERL) -I../../../../lib -e 'require "../PPPort.pm"; Devel::PPPort::WriteFile("ppport.h")'
	
EOM

sub MY::install { "install ::\n"  };
