
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => "Devel::PPPort::Harness",
	VERSION_FROM => 'Harness.pm',
	
	
	XSPROTOARG => '-noprototypes',
	#PM => {'Harness.pm' => '$(INST_LIBDIR)/Harness.pm'},
	#XS => {'Harness.xs' => 'Harness.c'},
	OBJECT => 'Harness$(OBJ_EXT) module2$(OBJ_EXT) module3$(OBJ_EXT)',
	'dist' => { COMPRESS=>"gzip", SUFFIX=>"gz" },
	'clean' => { FILES => 'ppport.h'},
	'depend' => { 'Harness.c'	=> 'ppport.h',
		      'module2.c'	=> 'ppport.h',
		      'module3.c'	=> 'ppport.h',
		    },

);

sub MY::postamble {

    my $pmfile;
    my $Ilibdir = '';

    if ($^O eq 'VMS') {
        $pmfile = '[-]PPPort.pm';
    }
    else {
        $pmfile = '../PPPort.pm';
    }

  my $retval = <<"EOM";

ppport.h:	$pmfile
	\$(PERL) "-I\$(PERL_ARCHLIB)" "-I\$(PERL_LIB)" -e "require qq{$pmfile}; Devel::PPPort::WriteFile(qq{ppport.h})"     

EOM
 
  return $retval;
}
