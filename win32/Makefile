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
#

INST_DRV=c:
INST_TOP=$(INST_DRV)\perl


##################### CHANGE THESE ONLY IF YOU MUST #####################

#
# Programs to compile, build .lib files and link
#

CC=cl.exe
LINK32=link.exe
LIB32=$(LINK32) -lib
#
# Options
#
PERLDLL  = -D "PERLDLL"
RUNTIME  = -MD
INCLUDES = -I ".\include" -I "." -I ".."
#PCHFLAGS = -Fp"$(INTDIR)/modules.pch" -YX 
DEFINES  = -D "WIN32" -D "_CONSOLE" -D "PERLDLL"
SUBSYS   = console
LIBFILES = kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib \
		advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib 

!IF "$(RUNTIME)" == "-MD"
WINIOMAYBE =
!ELSE
WINIOMAYBE = win32io.obj
!ENDIF

!IF  "$(CFG)" == "Debug"
!  IF "$(CCTYPE)" == "MSVC20"
OPTIMIZE = -Od $(RUNTIME) -Z7 -D "_DEBUG"
!  ELSE
OPTIMIZE = -Od $(RUNTIME)d -Z7 -D "_DEBUG"
!  ENDIF
LINK_DBG = -debug -pdb:none
!ELSE
!  IF "$(CCTYPE)" == "MSVC20"
OPTIMIZE = -Od $(RUNTIME) -D "NDEBUG"
!  ELSE
OPTIMIZE = -Od $(RUNTIME) -D "NDEBUG"
!  ENDIF
LINK_DBG = -release
!ENDIF

CFLAGS   = -nologo -W3 $(INCLUDES) $(DEFINES) $(PCHFLAGS) $(OPTIMIZE)
LINK_FLAGS  = -nologo $(LIBFILES) $(LINK_DBG) -machine:I386

#################### do not edit below this line #######################
############# NO USER-SERVICEABLE PARTS BEYOND THIS POINT ##############

#
# Rules
# 
.SUFFIXES : 
.SUFFIXES : .c .obj .dll .lib .exe

.c.obj:
	$(CC) -c $(CFLAGS) -Fo$@ $<

.obj.dll:
	$(LINK32) -dll -subsystem:windows -implib:$(*B).lib -def:$(*B).def -out:$@ $(LINK_FLAGS) $< $(LIBPERL)  

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

PL2BAT=bin\PL2BAT.BAT
MAKE=nmake -nologo
XCOPY=xcopy /i /d /f /r
NULL=

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
	..\util.c

CORE_OBJ=..\av.obj		\
	..\deb.obj	\
	..\doio.obj	\
	..\doop.obj	\
	..\dump.obj	\
	..\globals.obj	\
	..\gv.obj		\
	..\hv.obj		\
	..\mg.obj		\
	..\op.obj		\
	..\perl.obj	\
	..\perlio.obj	\
	..\perly.obj	\
	..\pp.obj		\
	..\pp_ctl.obj	\
	..\pp_hot.obj	\
	..\pp_sys.obj	\
	..\regcomp.obj	\
	..\regexec.obj	\
	..\run.obj	\
	..\scope.obj	\
	..\sv.obj		\
	..\taint.obj	\
	..\toke.obj	\
	..\universal.obj	\
	..\util.obj

WIN32_C = perllib.c \
	win32.c \
	win32io.c \
	win32sck.c \

WIN32_OBJ = win32.obj \
	win32io.obj \
	win32sck.obj \

DLL_OBJ = perllib.obj $(DYNALOADER).obj

CORE_H = "..\av.h"\
	"..\cop.h"\
	"..\cv.h"\
	"..\dosish.h"\
	"..\embed.h"\
	"..\form.h"\
	"..\gv.h"\
	"..\handy.h"\
	"..\hv.h"\
	"..\mg.h"\
	"..\nostdio.h"\
	"..\op.h"\
	"..\opcode.h"\
	"..\perl.h"\
	"..\perlio.h"\
	"..\perlsdio.h"\
	"..\perlsfio.h"\
	"..\perly.h"\
	"..\pp.h"\
	"..\proto.h"\
	"..\regexp.h"\
	"..\scope.h"\
	"..\sv.h"\
	"..\unixish.h"\
	"..\util.h"\
	"..\XSUB.h"\
	".\config.h"\
	"..\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys\socket.h"\
	".\win32.h"


EXTENSIONS=DynaLoader Socket IO Fcntl Opcode SDBM_File

DYNALOADER=$(EXTDIR)\DynaLoader\DynaLoader
SOCKET=$(EXTDIR)\Socket\Socket
FCNTL=$(EXTDIR)\Fcntl\Fcntl
OPCODE=$(EXTDIR)\Opcode\Opcode
SDBM_FILE=$(EXTDIR)\SDBM_File\SDBM_File
IO=$(EXTDIR)\IO\IO

SOCKET_DLL=..\lib\auto\Socket\Socket.dll
FCNTL_DLL=..\lib\auto\Fcntl\Fcntl.dll
OPCODE_DLL=..\lib\auto\Opcode\Opcode.dll
SDBM_FILE_DLL=..\lib\auto\SDBM_File\SDBM_File.dll
IO_DLL=..\lib\auto\IO\IO.dll

STATICLINKMODULES=DynaLoader
DYNALOADMODULES=	\
	$(SOCKET_DLL)	\
	$(FCNTL_DLL)	\
	$(OPCODE_DLL)	\
	$(SDBM_FILE_DLL)\
	$(IO_DLL)

POD2HTML=$(PODDIR)\pod2html
POD2MAN=$(PODDIR)\pod2man
POD2LATEX=$(PODDIR)\pod2latex
POD2TEXT=$(PODDIR)\pod2text

#
# Top targets
#

ALL: $(PERLEXE) $(GLOBEXE) $(DYNALOADMODULES) $(MINIMOD)

$(DYNALOADER).obj : $(DYNALOADER).c $(CORE_H) $(EXTDIR)\DynaLoader\dlutils.c

#------------------------------------------------------------

$(GLOBEXE): perlglob.obj
	$(LINK32) $(LINK_FLAGS) -out:$@ -subsystem:$(SUBSYS) perlglob.obj setargv.obj 

perlglob.obj  : perlglob.c

..\miniperlmain.obj : ..\miniperlmain.c $(CORE_H)

..\config.sh : config.w32 $(MINIPERL) config_sh.PL
	$(MINIPERL) -I..\lib config_sh.PL "INST_DRV=$(INST_DRV)" "INST_TOP=$(INST_TOP)"\
	"cc=$(CC)" "ccflags=$(RUNTIME) -DWIN32" config.w32 > ..\config.sh

$(CONFIGPM) : $(MINIPERL) ..\config.sh config_h.PL ..\minimod.pl
	cd .. && miniperl configpm
	if exist lib\* $(XCOPY) /e lib\*.* ..\lib\$(NULL)
	$(XCOPY) ..\*.h ..\lib\CORE\*.*
	$(XCOPY) *.h ..\lib\CORE\*.*
	$(XCOPY) /S include ..\lib\CORE\*.*
	$(MINIPERL) -I..\lib config_h.PL || $(MAKE) RUNTIME=$(RUNTIME) CFG=$(CFG) $(CONFIGPM)

$(MINIPERL) : ..\miniperlmain.obj $(CORE_OBJ) $(WIN32_OBJ)
	$(LINK32) -subsystem:console -out:$@ @<<
		$(LINK_FLAGS) ..\miniperlmain.obj $(CORE_OBJ) $(WIN32_OBJ)
<<

$(WIN32_OBJ) : $(CORE_H)
$(CORE_OBJ)  : $(CORE_H)
$(DLL_OBJ)   : $(CORE_H) 

perldll.def : $(MINIPERL) $(CONFIGPM)
	$(MINIPERL) -w makedef.pl > perldll.def

$(PERLDLL): perldll.def $(CORE_OBJ) $(WIN32_OBJ) $(DLL_OBJ)
	$(LINK32) -dll -def:perldll.def -out:$@ @<<
		$(LINK_FLAGS) $(CORE_OBJ) $(WIN32_OBJ) $(DLL_OBJ)
<<
	$(XCOPY) $(PERLIMPLIB) ..\lib\CORE

perl.def  : $(MINIPERL) makeperldef.pl
	$(MINIPERL) -I..\lib makeperldef.pl $(NULL) > perl.def

$(MINIMOD) : $(MINIPERL) ..\minimod.pl
	cd .. && miniperl minimod.pl > lib\ExtUtils\Miniperl.pm

perlmain.c : runperl.c 
	copy runperl.c perlmain.c

perlmain.obj : perlmain.c
	$(CC) $(CFLAGS) -U "PERLDLL" -c perlmain.c

$(PERLEXE): $(PERLDLL) $(CONFIGPM) perlmain.obj  
	$(LINK32) -subsystem:console -out:perl.exe $(LINK_FLAGS) perlmain.obj $(WINIOMAYBE) $(PERLIMPLIB) 
	copy perl.exe $@
	del perl.exe
	copy splittree.pl .. 
	$(MINIPERL) -I..\lib ..\splittree.pl "../LIB" "../LIB/auto"
	attrib -r ..\t\*.*
	copy test ..\t

$(DYNALOADER).c: $(MINIPERL) $(EXTDIR)\DynaLoader\dl_win32.xs $(CONFIGPM)
	if not exist ..\lib\auto md ..\lib\auto
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) dl_win32.xs > $(*B).c
	cd ..\..\win32

$(EXTDIR)\DynaLoader\dl_win32.xs: dl_win32.xs
	copy dl_win32.xs $(EXTDIR)\DynaLoader\dl_win32.xs

$(IO_DLL): $(PERLEXE) $(CONFIGPM) $(IO).xs
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\win32

$(SDBM_FILE_DLL) : $(PERLEXE) $(SDBM_FILE).xs
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\win32

$(FCNTL_DLL): $(PERLEXE) $(FCNTL).xs
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\win32

$(OPCODE_DLL): $(PERLEXE) $(OPCODE).xs
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\win32

$(SOCKET_DLL): $(SOCKET).xs $(PERLEXE)
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\win32

doc: $(PERLEXE)
	cd $(PODDIR)
	nmake -f ../win32/pod.mak
	cd ..\win32

utils: $(PERLEXE)
	cd ..\utils
	nmake PERL=$(MINIPERL)
	$(PERLEXE) ..\win32\$(PL2BAT) h2ph splain perlbug pl2pm c2ph \
			h2xs perldoc pstruct
	$(XCOPY) *.bat ..\win32\bin\*.*
	cd ..\win32

distclean: clean
	-del /f $(MINIPERL) $(PERLEXE) $(PERLDLL) $(GLOBEXE) \
		$(PERLIMPLIB) ..\miniperl.lib $(MINIMOD)
	-del /f *.def
	-del /f $(SOCKET_DLL) $(IO_DLL) $(SDBM_FILE_DLL) $(FCNTL_DLL) \
		$(OPCODE_DLL)
	-del /f $(SOCKET).c $(IO).c $(SDBM_FILE).c $(FCNTL).c $(OPCODE).c \
		$(DYNALOADER).c
	-del /f $(PODDIR)\*.html
	-del /f $(PODDIR)\*.bat
	-rmdir /s /q ..\lib\auto
	-rmdir /s /q ..\lib\CORE

install : ALL doc utils
	if not exist $(INST_TOP) mkdir $(INST_TOP)
	echo I $(INST_TOP) L $(LIBDIR)
	$(XCOPY) $(PERLEXE) $(INST_BIN)\*.*
	$(XCOPY) $(GLOBEXE) $(INST_BIN)\*.*
	$(XCOPY) $(PERLDLL) $(INST_BIN)\*.*
	$(XCOPY) bin\*.* $(INST_BIN)\*.*
	$(XCOPY) /e ..\lib $(INST_LIB)\*.*
	$(XCOPY) ..\pod\*.bat $(INST_BIN)\*.*
	$(XCOPY) ..\pod\*.pod $(INST_POD)\*.*
	$(XCOPY) ..\pod\*.html $(INST_HTML)\*.*

inst_lib : $(CONFIGPM)
	copy splittree.pl .. 
	$(MINIPERL) -I..\lib ..\splittree.pl "../LIB" "../LIB/auto"
	$(XCOPY) /e ..\lib $(INST_LIB)\*.*

minitest : $(MINIPERL) $(GLOBEXE) $(CONFIGPM)
	$(XCOPY) $(MINIPERL) ..\t\perl.exe
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
	attrib -r ..\t\*.*
	copy test ..\t
	cd ..\t
	$(MINIPERL) -I..\lib test base/*.t comp/*.t cmd/*.t io/*.t op/*.t pragma/*.t
	cd ..\win32

test : all
	$(XCOPY) $(PERLEXE) ..\t\$(NULL)
	$(XCOPY) $(PERLDLL) ..\t\$(NULL)
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
	cd ..\t
	$(PERLEXE) -I..\lib harness
	cd ..\win32

clean : 
	-@erase miniperlmain.obj
	-@erase $(MINIPERL)
	-@erase perlglob.obj
	-@erase perlmain.obj
	-@erase $(GLOBEXE)
	-@erase $(PERLEXE)
	-@erase $(PERLDLL)
	-@erase $(CORE_OBJ)
	-@erase $(WIN32_OBJ)
	-@erase $(DLL_OBJ)
	-@erase ..\*.obj *.obj ..\*.lib ..\*.exp
	-@erase *.ilk
	-@erase *.pdb


