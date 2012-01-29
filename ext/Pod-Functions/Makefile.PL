#!perl -w

use strict;
use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'Pod::Functions',
	      VERSION_FROM => 'Functions_pm.PL',
	      LICENSE => 'perl',
	      PREREQ_PM => {},
	      ABSTRACT_FROM => 'Functions_pm.PL',
	      AUTHOR => 'Perl 5 Porters <perlbug@perl.org>',
	      INSTALLDIRS => 'perl',
	      PL_FILES => {'Functions_pm.PL' => 'Functions.pm'},
	      PM => {'Functions.pm' => '$(INST_LIBDIR)/Functions.pm'},
	      clean => {FILES => 'Functions.pm'},
	     );
