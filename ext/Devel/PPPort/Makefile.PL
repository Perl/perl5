################################################################################
#
#  Makefile.PL -- generate Makefile
#
################################################################################
#
#  $Revision: 19 $
#  $Author: mhx $
#  $Date: 2006/01/19 19:35:25 +0100 $
#
################################################################################
#
#  Version 3.x, Copyright (C) 2004-2006, Marcus Holland-Moritz.
#  Version 2.x, Copyright (C) 2001, Paul Marquess.
#  Version 1.x, Copyright (C) 1999, Kenneth Albanowski.
#
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
################################################################################

use ExtUtils::MakeMaker;
require 5.003;

unless ($ENV{'PERL_CORE'}) {
  $ENV{'PERL_CORE'} = 1 if grep { $_ eq 'PERL_CORE=1' } @ARGV;
}

if ($ENV{'PERL_CORE'}) {
  # Pods will be built by installman.
  @moreopts = ( MAN3PODS => {} );
}
else {
  # Devel::PPPort is in the core since 5.7.3
  @moreopts = ( INSTALLDIRS => ($] >= 5.007003 ? 'perl' : 'site') );
}

@ARGV = map { /^--with-(.*)/ && ++$opt{$1} ? () : $_ } @ARGV;

%PL_FILES = ( 'ppport_h.PL'  => 'ppport.h' ),

@C_FILES  = qw{ module2.c module3.c };

@clean    = qw{ $(H_FILES) PPPort.c };

if ($opt{'apicheck'}) {
  $PL_FILES{'apicheck_c.PL'} = 'apicheck.c';
  push @C_FILES, qw{ apicheck.c };
  push @clean,   qw{ apicheck.c };
}

if (eval $ExtUtils::MakeMaker::VERSION >= 6) {
  push @moreopts, AUTHOR => 'Marcus Holland-Moritz <mhx@cpan.org>';
  if (-f 'PPPort.pm') {
    push @moreopts, ABSTRACT_FROM => 'PPPort.pm';
  }
}

if (eval $ExtUtils::MakeMaker::VERSION >= 6.30_01) {
  print "Setting license tag...\n";
  push @moreopts, LICENSE => 'perl';
}

WriteMakefile(
  NAME          => 'Devel::PPPort',
  VERSION_FROM  => 'PPPort_pm.PL',
  PL_FILES      => \%PL_FILES,
  PM            => { 'PPPort.pm' => '$(INST_LIBDIR)/PPPort.pm' },
  C             => \@C_FILES,
  H             => [ qw(ppport.h) ],
  OBJECT        => '$(BASEEXT)$(OBJ_EXT) $(O_FILES)',
  XSPROTOARG    => '-noprototypes',
  clean         => { FILES => "@clean" },
  depend        => { '$(OBJECT)' => '$(H_FILES)' },
  @moreopts,
);

sub MY::postamble {
  package MY;
  my $post = shift->SUPER::postamble(@_);
  $post .= <<'POSTAMBLE';

purge_all: realclean
	@$(RM_F) PPPort.pm PPPort.xs t/*.t

regen:
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) PPPort_pm.PL
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) PPPort_xs.PL
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) mktests.PL
	$(PERL) -I$(INST_ARCHLIB) -I$(INST_LIB) -I$(PERL_ARCHLIB) -I$(PERL_LIB) ppport_h.PL

POSTAMBLE
  return $post;
}

