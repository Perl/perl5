
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

sub MY::postamble {

  use File::Spec;

  my $libdir = File::Spec->catdir(File::Spec->updir(), File::Spec->updir(),  
				  File::Spec->updir(),  File::Spec->updir(),  
                                  'lib');
  my $blibdir = File::Spec->catdir(File::Spec->curdir(), 'blib');
  my $pmfile = File::Spec->catfile(File::Spec->updir(), 'PPPort.pm');
  my $retval = <<'EOM';

sweep:
	$(RM_F) pm_to_blib Harness.c Harness$(OBJ_EXT) module2$(OBJ_EXT) module3$(OBJ_EXT) ppport.h
EOM
 
  $retval .= "\t\$(RM_RF) $blibdir\n\n";
  $retval .= "Harness.c :      ppport.h\n\n";  
  $retval .= "module2.c module3.c : ppport.h\n\t\$(NOECHO) \$(NOOP)\n\n";  
  $retval .= "ppport.h: $pmfile\n";  

  my $Ilibdir = $^O eq 'VMS' ? qq{"-I$libdir"} : qq{-I$libdir};

  $pmfile =~ s:\\:\\\\:g;

  $retval .= qq[\t\$(PERL) $Ilibdir -e "require qq{$pmfile}; Devel::PPPort::WriteFile(qq{ppport.h})"];

  return $retval;
}

sub MY::install { "install ::\n"  };
