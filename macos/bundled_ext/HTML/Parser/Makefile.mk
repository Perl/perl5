# This Makefile is for the HTML::Parser extension to perl.
#
# It was generated automatically by MakeMaker version
# 3.25 (Revision: ) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	DEFINE => q[-DMARKED_SECTION]
#	H => [q[hparser.h], q[hctype.h], q[tokenpos.h], q[pfunc.h], q[hparser.c], q[util.c]]
#	NAME => q[HTML::Parser]
#	PREREQ_PM => { HTML::Tagset=>q[3] }
#	VERSION_FROM => q[Parser.pm]
#	dist => { COMPRESS=>q[gzip -9f], SUFFIX=>q[gz] }

# --- MakeMaker constants section:
NAME = HTML::Parser
DISTNAME = HTML-Parser
NAME_SYM = HTML_Parser
VERSION = 3.25
VERSION_SYM = 3_25
XS_VERSION = 3.25
INST_LIB = :::::lib
INST_ARCHLIB = :::::lib
PERL_LIB = :::::lib
PERL_SRC = :::::
MACPERL_SRC = :::::macos:
MACPERL_LIB = :::::macos:lib
PERL = :::::miniperl
FULLPERL = :::::perl
SOURCE =  Parser.c

MODULES = :lib:HTML:Entities.pm \
	:lib:HTML:Filter.pm \
	:lib:HTML:HeadParser.pm \
	:lib:HTML:LinkExtor.pm \
	:lib:HTML:PullParser.pm \
	:lib:HTML:TokeParser.pm \
	Parser.pm
PMLIBDIRS = lib


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
FULLEXT = HTML:Parser
BASEEXT = Parser
ROOTEXT = HTML:
DEFINE = -d MARKED_SECTION $(XS_DEFINE_VERSION) $(DEFINE_VERSION)

# Handy lists of source code files:
XS_FILES= Parser.xs
C_FILES = Parser.c \
	hparser.c \
	util.c
H_FILES = hparser.h \
	hctype.h \
	tokenpos.h \
	pfunc.h \
	hparser.c \
	util.c


.INCLUDE : $(MACPERL_SRC)ExtBuildRules.mk


# --- MakeMaker dlsyms section:

dynamic :: Parser.exp


Parser.exp: Makefile.PL
	$(PERL) "-I$(PERL_LIB)" -e 'use ExtUtils::Mksymlists; Mksymlists("NAME" => "HTML::Parser", "DL_FUNCS" => {  }, "DL_VARS" => []);'


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

ProcessPL :: pfunc.h hctype.h
	$(NOOP)

# --- MakeMaker clean section:

# Delete temporary files but do not touch installed files. We don't delete
# the Makefile here so a later make realclean still has a makefile to use.

clean ::
	$(RM_RF) Parser.c
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"HTML-Parser\" VERSION=\"3,25,0,0\">\n}. qq{\t<TITLE>HTML-Parser</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR></AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<DEPENDENCY NAME=\"HTML-Tagset\" VERSION=\"3,0,0,0\" />\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > HTML-Parser.ppd

# --- MakeMaker postamble section:

pfunc.h : mkpfunc
	$(PERL) mkpfunc >pfunc.h

hctype.h : mkhctype
	$(PERL) mkhctype >hctype.h


# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(MACPERL_SRC)PerlInstall -l $(PERL_LIB)

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk


# End.
