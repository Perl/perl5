# This Makefile is for the Digest::MD5 extension to perl.
#
# It was generated automatically by MakeMaker version
# 2.16 (Revision: ) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	NAME => q[Digest::MD5]
#	VERSION_FROM => q[MD5.pm]
#	dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }

# --- MakeMaker constants section:
NAME = Digest::MD5
DISTNAME = Digest-MD5
NAME_SYM = Digest_MD5
VERSION = 2.16
VERSION_SYM = 2_16
XS_VERSION = 2.16
INST_LIB = :::::lib
INST_ARCHLIB = :::::lib
PERL_LIB = :::::lib
PERL_SRC = :::::
MACPERL_SRC = :::::macos:
MACPERL_LIB = :::::macos:lib
PERL = :::::miniperl
FULLPERL = :::::perl
SOURCE =  MD5.c

MODULES = MD5.pm

MWCPPCOptimize = -O1

.INCLUDE : $(MACPERL_SRC)BuildRules.mk


VERSION_MACRO = VERSION
DEFINE_VERSION = -d $(VERSION_MACRO)="¶"$(VERSION)¶""
XS_VERSION_MACRO = XS_VERSION
XS_DEFINE_VERSION = -d $(XS_VERSION_MACRO)="¶"$(XS_VERSION)¶""

MAKEMAKER = Bird:tmp:perl:macos::lib:ExtUtils:MakeMaker.pm
MM_VERSION = 5.45

# FULLEXT = Pathname for extension directory (eg DBD:Oracle).
# BASEEXT = Basename part of FULLEXT. May be just equal FULLEXT.
# ROOTEXT = Directory part of FULLEXT (eg DBD)
# DLBASE  = Basename part of dynamic library. May be just equal BASEEXT.
FULLEXT = Digest:MD5
BASEEXT = MD5
ROOTEXT = Digest:
DEFINE =  $(XS_DEFINE_VERSION) $(DEFINE_VERSION)

# Handy lists of source code files:
XS_FILES= MD5.xs
C_FILES = MD5.c
H_FILES = 


.INCLUDE : $(MACPERL_SRC)ExtBuildRules.mk


# --- MakeMaker dlsyms section:

dynamic :: MD5.exp


MD5.exp: Makefile.PL
	$(PERL) "-I$(PERL_LIB)" -e 'use ExtUtils::Mksymlists; Mksymlists("NAME" => "Digest::MD5", "DL_FUNCS" => {  }, "DL_VARS" => []);'


# --- MakeMaker dynamic section:

all :: dynamic

install :: do_install_dynamic

install_dynamic :: do_install_dynamic


# --- MakeMaker static section:

all :: static

install :: do_install_static

install_static :: do_install_static


# --- MakeMaker htmlifypods section:

htmlifypods : pure_all
	$(NOOP)


# --- MakeMaker processPL section:


# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	$(RM_RF) MD5.c
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"Digest-MD5\" VERSION=\"2,16,0,0\">\n}. qq{\t<TITLE>Digest-MD5</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR></AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > Digest-MD5.ppd

# --- MakeMaker postamble section:


# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(MACPERL_SRC)PerlInstall -l $(PERL_LIB)

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk


# End.
