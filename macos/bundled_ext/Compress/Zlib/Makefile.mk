# This Makefile is for the Compress::Zlib extension to perl.
#
# It was generated automatically by MakeMaker version
#  (Revision: ) from the contents of
# Makefile.PL. Don't edit this file, edit Makefile.PL instead.
#
#	ANY CHANGES MADE HERE WILL BE LOST!
#
#   MakeMaker Parameters:

#	ABSTRACT_FROM => q[Zlib.pm]
#	AUTHOR => q[Paul Marquess <Paul.Marquess@btinternet.com>]
#	INC => q[-I/usr/local/include]
#	LIBS => [q[-L/usr/local/lib -lz ]]
#	NAME => q[Compress::Zlib]
#	VERSION_FROM => q[Zlib.pm]
#	depend => { dist=>q[MyRelease] }
#	dist => { COMPRESS=>q[gzip], SUFFIX=>q[gz] }

# --- MakeMaker constants section:
NAME = Compress::Zlib
DISTNAME = Compress-Zlib
NAME_SYM = Compress_Zlib
VERSION = 1.13
VERSION_SYM = 1_13
XS_VERSION = 1.13
INST_LIB = :::::lib
INST_ARCHLIB = :::::lib
PERL_LIB = :::::lib
PERL_SRC = :::::
MACPERL_SRC = :::::macos:
MACPERL_LIB = :::::macos:lib
PERL = :::::miniperl
FULLPERL = :::::perl
SOURCE =  Zlib.c \
	adler32.c \
	compress.c \
	crc32.c \
	deflate.c \
	gzio.c \
	infblock.c \
	infcodes.c \
	inffast.c \
	inflate.c \
	inftrees.c \
	infutil.c \
	maketree.c \
	trees.c \
	uncompr.c \
	zutil.c

MODULES = Zlib.pm


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
FULLEXT = Compress:Zlib
BASEEXT = Zlib
ROOTEXT = Compress:
DEFINE =  $(XS_DEFINE_VERSION) $(DEFINE_VERSION)
INC = 

# Handy lists of source code files:
XS_FILES= Zlib.xs
C_FILES = Zlib.c \
	adler32.c \
	compress.c \
	crc32.c \
	deflate.c \
	gzio.c \
	infblock.c \
	infcodes.c \
	inffast.c \
	inflate.c \
	inftrees.c \
	infutil.c \
	maketree.c \
	trees.c \
	uncompr.c \
	zutil.c
H_FILES = deflate.h \
	infblock.h \
	infcodes.h \
	inffast.h \
	inffixed.h \
	inftrees.h \
	infutil.h \
	trees.h \
	zconf.h \
	zlib.h \
	zutil.h


.INCLUDE : $(MACPERL_SRC)ExtBuildRules.mk


# --- MakeMaker dlsyms section:

dynamic :: Zlib.exp


Zlib.exp: Makefile.PL
	$(PERL) "-I$(PERL_LIB)" -e 'use ExtUtils::Mksymlists; Mksymlists("NAME" => "Compress::Zlib", "DL_FUNCS" => {  }, "DL_VARS" => []);'


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
	$(RM_RF) Zlib.c
	$(MV) Makefile.mk Makefile.mk.old


# --- MakeMaker realclean section:

# Delete temporary files (via clean) and also delete installed files
realclean purge ::  clean
	$(RM_RF) Makefile.mk Makefile.mk.old


# --- MakeMaker ppd section:
# Creates a PPD (Perl Package Description) for a binary distribution.
ppd:
	@$(PERL) -e "print qq{<SOFTPKG NAME=\"Compress-Zlib\" VERSION=\"0,10,0,0\">\n}. qq{\t<TITLE>Compress-Zlib</TITLE>\n}. qq{\t<ABSTRACT></ABSTRACT>\n}. qq{\t<AUTHOR>Paul Marquess &lt;Paul.Marquess\@btinternet.com&gt;</AUTHOR>\n}. qq{\t<IMPLEMENTATION>\n}. qq{\t\t<OS NAME=\"$(OSNAME)\" />\n}. qq{\t\t<ARCHITECTURE NAME=\"\" />\n}. qq{\t\t<CODEBASE HREF=\"\" />\n}. qq{\t</IMPLEMENTATION>\n}. qq{</SOFTPKG>\n}" > Compress-Zlib.ppd

# --- MakeMaker postamble section:

MyRelease:	
	echo hello

Zlib.xs:	typemap
	@$(TOUCH) Zlib.xs

Makefile:	config.in



# --- MakeMaker rulez section:

install install_static install_dynamic :: 
	$(MACPERL_SRC)PerlInstall -l $(PERL_LIB)

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk


# End.
