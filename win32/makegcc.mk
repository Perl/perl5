#
# Makefile to build perl on Windowns NT using Microsoft NMAKE.
#
#
# This is set up to build a perl.exe that runs off a shared library
# (perl.dll).  Also makes individual DLLs for the XS extensions.
#

#
# Set these to wherever you want "nmake install" to put your
# newly built perl.
INST_DRV=c:
INST_TOP=$(INST_DRV)\perl5004.5x
#BUILDOPT=-DUSE_THREADS


#
# uncomment one if you are using Visual C++ 2.x or Borland
# comment out both if you are using Visual C++ 4.x and above
#CCTYPE=MSVC20
CCTYPE=GCC

#
# uncomment next line if you want debug version of perl (big,slow)
#CFG=Debug

#
# set the install locations of the compiler include/libraries
#CCHOME = f:\msdev\vc
CCHOME = C:\Mingw32
CCINCDIR = $(CCHOME)\include
CCLIBDIR = $(CCHOME)\lib

#
# set this to point to cmd.exe (only needed if you use some
# alternate shell that doesn't grok cmd.exe style commands)
#SHELL = g:\winnt\system32\cmd.exe

#
# set this to your email address (perl will guess a value from
# from your loginname and your hostname, which may not be right)
#EMAIL = 

##################### CHANGE THESE ONLY IF YOU MUST #####################

#
# Programs to compile, build .lib files and link
#

.USESHELL :

CC = gcc
LINK32 = gcc
LIB32 = ar
IMPLIB = dlltool

#
# Options
#
RUNTIME  = -D_RTLDLL
INCLUDES = -I.\include -I. -I.. 
DEFINES  = -DWIN32 $(BUILDOPT) 
LOCDEFS  = -DPERLDLL -DPERL_CORE
SUBSYS   = console
LIBC     = -lcrtdll
LIBFILES = -ladvapi32 -luser32 -lwsock32 -lmingw32 -lgcc -lmoldname $(LIBC) -lkernel32 

WINIOMAYBE =

.IF  "$(CFG)" == "Debug"
OPTIMIZE = -g -O2 $(RUNTIME)
LINK_DBG = -g
.ELSE
OPTIMIZE = -O2 $(RUNTIME)
LINK_DBG = 
.ENDIF

CFLAGS   = $(INCLUDES) $(DEFINES) $(LOCDEFS) $(OPTIMIZE)
LINK_FLAGS  = -v $(LINK_DBG) -L$(CCLIBDIR) 
OBJOUT_FLAG = -o 

#################### do not edit below this line #######################
############# NO USER-SERVICEABLE PARTS BEYOND THIS POINT ##############

#
# Rules
# 
.SUFFIXES : 
.SUFFIXES : .c .obj .dll .lib .exe

.c.obj:
	$(CC) -c $(CFLAGS) $(OBJOUT_FLAG) $@ $<

.c.i:
	$(CC) -E $(CFLAGS) $(OBJOUT_FLAG) $@ $<

.obj.dll:
	$(LINK32) -o $@ $(LINK_FLAGS) $< $(LIBFILES),
	$(IMPLIB) -def $(*B).def $(*B).lib $@

#
INST_BIN=$(INST_TOP)\bin
INST_LIB=$(INST_TOP)\lib
INST_POD=$(INST_LIB)\pod
INST_HTML=$(INST_POD)\html
LIBDIR=..\lib
EXTDIR=..\ext
PODDIR=..\pod
EXTUTILSDIR=$(LIBDIR)\extutils

#
# various targets
PERLIMPLIB=..\perl.lib
MINIPERL=..\miniperl.exe
PERLDLL=..\perl.dll
PERLEXE=..\perl.exe
GLOBEXE=..\perlglob.exe
CONFIGPM=..\lib\Config.pm
MINIMOD=..\lib\ExtUtils\Miniperl.pm

PL2BAT=bin\pl2bat.pl
GLOBBAT = bin\perlglob.bat


# Borland wildargs is incompatible with MS setargv
CFGSH_TMPL = config.gc
CFGH_TMPL = config_H.gc
# Borland's perl.exe will work on W95, so we don't make this

XCOPY=xcopy /f /r /i /d
RCOPY=xcopy /f /r /i /e /d
#NULL=

#
# filenames given to xsubpp must have forward slashes (since it puts
# full pathnames in #line strings)
XSUBPP=..\$(MINIPERL) -I..\..\lib ..\$(EXTUTILSDIR)\xsubpp -C++ -prototypes

CORE_C=	..\av.c		\
	..\deb.c	\
	..\doio.c	\
	..\doop.c	\
	..\dump.c	\
	..\globals.c	\
	..\gv.c		\
	..\hv.c		\
	..\mg.c		\
	..\op.c		\
	..\perl.c	\
	..\perlio.c	\
	..\perly.c	\
	..\pp.c		\
	..\pp_ctl.c	\
	..\pp_hot.c	\
	..\pp_sys.c	\
	..\regcomp.c	\
	..\regexec.c	\
	..\run.c	\
	..\scope.c	\
	..\sv.c		\
	..\taint.c	\
	..\toke.c	\
	..\universal.c	\
	..\util.c	\
	..\malloc.c

CORE_OBJ= ..\av.obj	\
	..\deb.obj	\
	..\doio.obj	\
	..\doop.obj	\
	..\dump.obj	\
	..\globals.obj	\
	..\gv.obj	\
	..\hv.obj	\
	..\mg.obj	\
	..\op.obj	\
	..\perl.obj	\
	..\perlio.obj	\
	..\perly.obj	\
	..\pp.obj	\
	..\pp_ctl.obj	\
	..\pp_hot.obj	\
	..\pp_sys.obj	\
	..\regcomp.obj	\
	..\regexec.obj	\
	..\run.obj	\
	..\scope.obj	\
	..\sv.obj	\
	..\taint.obj	\
	..\toke.obj	\
	..\universal.obj\
	..\util.obj     \
	..\malloc.obj

WIN32_C = perllib.c \
	win32.c \
	win32sck.c \
	win32thread.c 

WIN32_OBJ = win32.obj \
	win32sck.obj \
	win32thread.obj

PERL95_OBJ = perl95.obj \
	win32mt.obj \
	win32sckmt.obj

DLL_OBJ = perllib.obj $(DYNALOADER).obj

CORE_H = ..\av.h	\
	..\cop.h	\
	..\cv.h		\
	..\dosish.h	\
	..\embed.h	\
	..\form.h	\
	..\gv.h		\
	..\handy.h	\
	..\hv.h		\
	..\mg.h		\
	..\nostdio.h	\
	..\op.h		\
	..\opcode.h	\
	..\perl.h	\
	..\perlio.h	\
	..\perlsdio.h	\
	..\perlsfio.h	\
	..\perly.h	\
	..\pp.h		\
	..\proto.h	\
	..\regexp.h	\
	..\scope.h	\
	..\sv.h		\
	..\thread.h	\
	..\unixish.h	\
	..\util.h	\
	..\XSUB.h	\
	.\config.h	\
	..\EXTERN.h	\
	.\include\dirent.h	\
	.\include\netdb.h	\
	.\include\sys\socket.h	\
	.\win32.h

DYNAMIC_EXT=Socket IO Fcntl Opcode SDBM_File attrs Thread
STATIC_EXT=DynaLoader

DYNALOADER=$(EXTDIR)\DynaLoader\DynaLoader
SOCKET=$(EXTDIR)\Socket\Socket
FCNTL=$(EXTDIR)\Fcntl\Fcntl
OPCODE=$(EXTDIR)\Opcode\Opcode
SDBM_FILE=$(EXTDIR)\SDBM_File\SDBM_File
IO=$(EXTDIR)\IO\IO
ATTRS=$(EXTDIR)\attrs\attrs
THREAD=$(EXTDIR)\Thread\Thread

SOCKET_DLL=..\lib\auto\Socket\Socket.dll
FCNTL_DLL=..\lib\auto\Fcntl\Fcntl.dll
OPCODE_DLL=..\lib\auto\Opcode\Opcode.dll
SDBM_FILE_DLL=..\lib\auto\SDBM_File\SDBM_File.dll
IO_DLL=..\lib\auto\IO\IO.dll
ATTRS_DLL=..\lib\auto\attrs\attrs.dll
THREAD_DLL=..\lib\auto\Thread\Thread.dll

STATICLINKMODULES=DynaLoader
DYNALOADMODULES=	\
	$(SOCKET_DLL)	\
	$(FCNTL_DLL)	\
	$(OPCODE_DLL)	\
	$(SDBM_FILE_DLL)\
	$(IO_DLL)	\
	$(ATTRS_DLL)	\
	$(THREAD_DLL)

POD2HTML=$(PODDIR)\pod2html
POD2MAN=$(PODDIR)\pod2man
POD2LATEX=$(PODDIR)\pod2latex
POD2TEXT=$(PODDIR)\pod2text

#
# Top targets
#
MAKE = dmake

all: $(PERLEXE) $(PERL95EXE) $(GLOBEXE) $(DYNALOADMODULES) $(MINIMOD) $(GLOBBAT)

$(DYNALOADER).obj : $(DYNALOADER).c $(CORE_H) $(EXTDIR)\DynaLoader\dlutils.c

#------------------------------------------------------------

$(GLOBEXE): perlglob.obj
	$(LINK32) $(LINK_FLAGS) -o $@  \
	    perlglob.obj $(LIBFILES) 

$(GLOBBAT) : ..\lib\File\DosGlob.pm $(MINIPERL)
	$(MINIPERL) $(PL2BAT) - < ..\lib\File\DosGlob.pm > $(GLOBBAT)

perlglob.obj  : perlglob.c

..\miniperlmain.obj : ..\miniperlmain.c $(CORE_H)

config.w32 : $(CFGSH_TMPL)
	copy $(CFGSH_TMPL) config.w32

.\config.h : $(CFGH_TMPL)
	-del /f config.h
	copy $(CFGH_TMPL) config.h

..\config.sh : config.w32 $(MINIPERL) config_sh.PL
	$(MINIPERL) -I..\lib config_sh.PL "INST_DRV=$(INST_DRV)" \
	    "INST_TOP=$(INST_TOP)" "cc=$(CC)" "ccflags=$(OPTIMIZE) $(DEFINES)" \
	    "cf_email=$(EMAIL)" "libs=$(LIBFILES:f)" "incpath=$(CCINCDIR)" \
	    "libpth=$(strip $(CCLIBDIR) $(LIBFILES:d))" "libc=$(LIBC)" \
            "static_ext=$(STATIC_EXT)" "dynamic_ext=$(DYNAMIC_EXT)" \
            "ldflags=$(LINK_FLAGS)" "optimize=$(OPTIMIZE)" \
	    config.w32 > ..\config.sh

$(CONFIGPM) : $(MINIPERL) ..\config.sh config_h.PL ..\minimod.pl
	cd .. && miniperl configpm
	if exist lib\* $(RCOPY) lib\*.* ..\lib\$(NULL)
	$(XCOPY) ..\*.h ..\lib\CORE\*.*
	$(XCOPY) *.h ..\lib\CORE\*.*
	$(RCOPY) include ..\lib\CORE\*.*
	$(MINIPERL) -I..\lib config_h.PL || $(MAKE) CCTYPE=$(CCTYPE) \
	    RUNTIME=$(RUNTIME) CFG=$(CFG) $(CONFIGPM)

LKPRE = INPUT (
LKPOST = )

linkscript  : ..\miniperlmain.obj $(CORE_OBJ) $(WIN32_OBJ)
	type $(mktmp $(LKPRE) ..\miniperlmain.obj \
		$(CORE_OBJ:s,\,\\) $(WIN32_OBJ:s,\,\\) $(LIBFILES) $(LKPOST))



$(MINIPERL) : ..\miniperlmain.obj $(CORE_OBJ) $(WIN32_OBJ)
	$(LINK32) -v -o $@ $(LINK_FLAGS) \
	    $(mktmp $(LKPRE) ..\miniperlmain.obj \
		$(CORE_OBJ:s,\,\\) $(WIN32_OBJ:s,\,\\) $(LIBFILES) $(LKPOST))

$(WIN32_OBJ) : $(CORE_H)
$(CORE_OBJ)  : $(CORE_H)
$(DLL_OBJ)   : $(CORE_H) 

perldll.def : $(MINIPERL) $(CONFIGPM) ..\global.sym makedef.pl
	$(MINIPERL) -w makedef.pl $(DEFINES) $(CCTYPE) > perldll.def

$(PERLDLL): perldll.def $(CORE_OBJ) $(WIN32_OBJ) $(DLL_OBJ)
	$(LINK32) -dll -o $@ -Wl,--base-file -Wl,perl.base $(LINK_FLAGS) \
	    $(mktmp $(LKPRE) $(CORE_OBJ:s,\,\\) \
		$(WIN32_OBJ:s,\,\\) $(DLL_OBJ:s,\,\\) $(LIBFILES) $(LKPOST))
	dlltool --output-lib $(PERLIMPLIB) \
                --dllname perl.dll \
                --def perldll.def \
                --base-file perl.base \
                --output-exp perl.exp
	$(LINK32) -dll -o $@ $(LINK_FLAGS) \
	    $(mktmp $(LKPRE) $(CORE_OBJ:s,\,\\) \
		$(WIN32_OBJ:s,\,\\) $(DLL_OBJ:s,\,\\) $(LIBFILES) perl.exp $(LKPOST))
	$(XCOPY) $(PERLIMPLIB) ..\lib\CORE

perl.def  : $(MINIPERL) makeperldef.pl
	$(MINIPERL) -I..\lib makeperldef.pl $(NULL) > perl.def

$(MINIMOD) : $(MINIPERL) ..\minimod.pl
	cd .. && miniperl minimod.pl > lib\ExtUtils\Miniperl.pm

perlmain.c : runperl.c 
	copy runperl.c perlmain.c

perlmain.obj : perlmain.c
	$(CC) $(CFLAGS) -UPERLDLL -o $@ -c perlmain.c


$(PERLEXE): $(PERLDLL) $(CONFIGPM) perlmain.obj  
	$(LINK32) -o perl.exe $(LINK_FLAGS)  \
	perlmain.obj $(WINIOMAYBE) $(PERLIMPLIB) $(LIBFILES)
	copy perl.exe $@
	del perl.exe
	copy splittree.pl .. 
	$(MINIPERL) -I..\lib ..\splittree.pl "../LIB" "../LIB/auto"


$(DYNALOADER).c: $(MINIPERL) $(EXTDIR)\DynaLoader\dl_win32.xs $(CONFIGPM)
	if not exist ..\lib\auto mkdir ..\lib\auto
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B) && $(XSUBPP) dl_win32.xs > $(*B).c
	$(XCOPY) $(EXTDIR)\$(*B)\dlutils.c .

$(EXTDIR)\DynaLoader\dl_win32.xs: dl_win32.xs
	copy dl_win32.xs $(EXTDIR)\DynaLoader\dl_win32.xs

$(THREAD_DLL): $(PERLEXE) $(THREAD).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

$(ATTRS_DLL): $(PERLEXE) $(ATTRS).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

$(IO_DLL): $(PERLEXE) $(IO).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

$(SDBM_FILE_DLL) : $(PERLEXE) $(SDBM_FILE).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

$(FCNTL_DLL): $(PERLEXE) $(FCNTL).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

$(OPCODE_DLL): $(PERLEXE) $(OPCODE).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

$(SOCKET_DLL): $(PERLEXE) $(SOCKET).xs
	cd $(EXTDIR)\$(*B) && \
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	cd $(EXTDIR)\$(*B) && $(MAKE)

doc: $(PERLEXE)
	cd ..\pod && $(MAKE) -f ..\win32\pod.mak checkpods \
		pod2html pod2latex pod2man pod2text
	cd ..\pod && $(XCOPY) *.bat ..\win32\bin\*.*
	copy ..\README.win32 ..\pod\perlwin32.pod
	$(PERLEXE) ..\installhtml --podroot=.. --htmldir=./html \
	    --podpath=pod:lib:ext:utils --htmlroot="//$(INST_HTML:s,:,|,)" \
	    --libpod=perlfunc:perlguts:perlvar:perlrun:perlop --recurse

utils: $(PERLEXE)
	cd ..\utils && $(MAKE) PERL=$(MINIPERL)
	cd ..\utils && $(PERLEXE) ..\win32\$(PL2BAT) h2ph splain perlbug \
		pl2pm c2ph h2xs perldoc pstruct
	$(XCOPY) ..\utils\*.bat bin\*.*
	$(PERLEXE) $(PL2BAT) bin\network.pl bin\www.pl bin\runperl.pl \
			bin\pl2bat.pl

distclean: clean
	-del /f $(MINIPERL) $(PERLEXE) $(PERL95EXE) $(PERLDLL) $(GLOBEXE) \
		$(PERLIMPLIB) ..\miniperl.lib $(MINIMOD)
	-del /f *.def *.map
	-del /f $(SOCKET_DLL) $(IO_DLL) $(SDBM_FILE_DLL) $(FCNTL_DLL) \
		$(OPCODE_DLL) $(ATTRS_DLL) $(THREAD_DLL)
	-del /f $(SOCKET).c $(IO).c $(SDBM_FILE).c $(FCNTL).c $(OPCODE).c \
		$(DYNALOADER).c $(ATTRS).c $(THREAD).c
	-del /f $(PODDIR)\*.html
	-del /f $(PODDIR)\*.bat
	-del /f ..\config.sh ..\splittree.pl perlmain.c dlutils.c config.h.new
.IF "$(PERL95EXE)" != ""
	-del /f perl95.c
.ENDIF
	-del /f bin\*.bat
	-cd $(EXTDIR) && del /s *.lib *.def *.map *.bs Makefile *.obj pm_to_blib
	-rmdir /s /q ..\lib\auto
	-rmdir /s /q ..\lib\CORE

install : all doc utils
	if not exist $(INST_TOP) mkdir $(INST_TOP)
	echo I $(INST_TOP) L $(LIBDIR)
	$(XCOPY) $(PERLEXE) $(INST_BIN)\*.*
.IF "$(PERL95EXE)" != ""
	$(XCOPY) $(PERL95EXE) $(INST_BIN)\*.*
.ENDIF
	$(XCOPY) $(GLOBEXE) $(INST_BIN)\*.*
	$(XCOPY) $(PERLDLL) $(INST_BIN)\*.*
	$(XCOPY) bin\*.bat $(INST_BIN)\*.*
	$(RCOPY) ..\lib $(INST_LIB)\*.*
	$(XCOPY) ..\pod\*.bat $(INST_BIN)\*.*
	$(XCOPY) ..\pod\*.pod $(INST_POD)\*.*
	$(RCOPY) html\*.* $(INST_HTML)\*.*

inst_lib : $(CONFIGPM)
	copy splittree.pl .. 
	$(MINIPERL) -I..\lib ..\splittree.pl "../LIB" "../LIB/auto"
	$(RCOPY) ..\lib $(INST_LIB)\*.*

minitest : $(MINIPERL) $(GLOBEXE) $(CONFIGPM)
	$(XCOPY) $(MINIPERL) ..\t\perl.exe
.IF "$(CCTYPE)" == "BORLAND"
	$(XCOPY) $(GLOBBAT) ..\t\$(NULL)
.ELSE
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
.ENDIF
	attrib -r ..\t\*.*
	copy test ..\t
	cd ..\t && \
	$(MINIPERL) -I..\lib test base/*.t comp/*.t cmd/*.t io/*.t op/*.t pragma/*.t

test-prep : all
	$(XCOPY) $(PERLEXE) ..\t\$(NULL)
	$(XCOPY) $(PERLDLL) ..\t\$(NULL)
.IF "$(CCTYPE)" == "BORLAND"
	$(XCOPY) $(GLOBBAT) ..\t\$(NULL)
.ELSE
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
.ENDIF

test : test-prep
	cd ..\t && $(PERLEXE) -I..\lib harness

test-notty : test-prep
	set PERL_SKIP_TTY_TEST=1 && \
	cd ..\t && $(PERLEXE) -I.\lib harness

clean : 
	-@erase miniperlmain.obj
	-@erase $(MINIPERL)
	-@erase perlglob.obj
	-@erase perlmain.obj
	-@erase config.w32
	-@erase /f config.h
	-@erase $(GLOBEXE)
	-@erase $(PERLEXE)
	-@erase $(PERLDLL)
	-@erase $(CORE_OBJ)
	-@erase $(WIN32_OBJ)
	-@erase $(DLL_OBJ)
	-@erase ..\*.obj ..\*.lib ..\*.exp *.obj *.lib *.exp
	-@erase ..\t\*.exe ..\t\*.dll ..\t\*.bat
	-@erase *.ilk
	-@erase *.pdb




