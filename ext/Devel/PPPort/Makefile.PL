use ExtUtils::MakeMaker;

WriteMakefile(
    NAME	=> "Devel::PPPort",
    DISTNAME	=> "Devel-PPPort",
    VERSION_FROM=> 'PPPort.pm',

    #PM		=> {'PPPort.pm' => '$(INST_LIBDIR)/PPPort.pm'},
    C		=> [qw(module2.c module3.c)],
    H		=> [qw(ppport.h)],
    OBJECT	=> '$(BASEEXT)$(OBJ_EXT) $(O_FILES)',
    XSPROTOARG	=> '-noprototypes',
    'dist'	=> { COMPRESS=>"gzip", SUFFIX=>"gz" },
    'clean'	=> { FILES => qw($(H_FILES))}
);

sub MY::postamble {
    return <<"EOM";

\$(H_FILES)  :	ppport_h.PL
	\$(PERLRUNINST) ppport_h.PL

\$(OBJECT)   :	\$(H_FILES)

EOM
}
