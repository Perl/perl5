
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> "Devel::PPPort",
    DISTNAME	=> "Devel-PPPort",
    VERSION_FROM=> 'PPPort.pm',

    #PM		=> {'PPPort.pm' => '$(INST_LIBDIR)/PPPort.pm'},
    OBJECT	=> 'PPPort$(OBJ_EXT) module2$(OBJ_EXT) module3$(OBJ_EXT)',
    XSPROTOARG	=> '-noprototypes',
    'dist'	=> { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'clean'	=> { FILES => [qw(ppport.h ppport_h)]},
);

sub MY::postamble {
    return <<"EOM";

ppport.h:	ppport_h
	\$(TOUCH) ppport_h

PPPort\$(OBJ_EXT) module2\$(OBJ_EXT) module3\$(OBJ_EXT): ppport.h

EOM
}
