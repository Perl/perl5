
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> "Devel::PPPort",
    DISTNAME	=> "Devel-PPPort",
    VERSION_FROM=> 'PPPort.pm',

    #PM		=> {'PPPort.pm' => '$(INST_LIBDIR)/PPPort.pm'}, 
    OBJECT	=> 'PPPort$(OBJ_EXT) module2$(OBJ_EXT) module3$(OBJ_EXT)',
    XSPROTOARG	=> '-noprototypes',
    'dist'	=> { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'clean'	=> { FILES => 'ppport.h'},
);

sub MY::postamble {

    my $pmfile = 'PPPort.pm' ;

    my $retval = <<"EOM";

ppport.h:	ppport_h.PL
	\$(PERL) "-I\$(PERL_ARCHLIB)" "-I\$(PERL_LIB)"  ppport_h.PL > ppport.h     

PPPort.xs module2.c module3.c : ppport.h
	-\$(TOUCH) \$@

EOM
 
    return $retval;
}
