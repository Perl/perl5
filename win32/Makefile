#
# Makefile to build perl on Windowns NT using Microsoft NMAKE.
#
#
# This is set up to build a perl.exe that runs off a shared library
# (perl.dll).  Also makes individual DLLs for the XS extensions.
#
# There's no support for building an all-static perl yet.
# Doesn't build any of the stuff in ..\utils yet.
# No support for installing documentation, uh, yet.
#


#
# Set this to wherever you want "nmake install" to put your
# newly built perl.  If you change this, you better change
# all occurrences of this prefix in $(INST_TOP)\lib\Config.pm
# as well.

INST_TOP=C:\perl

#################### do not edit below this line ########################
#
INST_BIN=$(INST_TOP)\bin
INST_LIB=$(INST_TOP)\lib
INST_POD=$(INST_TOP)\pod
INST_HTML=$(INST_POD)\html
LIBDIR=..\lib
EXTDIR=..\ext
PODDIR=..\pod
EXTUTILSDIR=$(LIBDIR)\extutils

#
# various targets
PERLLIB=..\libperl.lib
PERLIMPLIB=..\perl.lib
MINIPERL=..\miniperl.exe
PERLDLL=..\perl.dll
PERLEXE=..\perl.exe
GLOBEXE=..\perlglob.exe

PL2BAT=bin\PL2BAT.BAT
MAKE=nmake /nologo
XCOPY=xcopy /i /d /f /r
NULL=

#
# filenames given to xsubpp must have forward slashes (since it puts
# full pathnames in #line strings)
XSUBPP=..\$(MINIPERL) ..\$(EXTUTILSDIR)\xsubpp -C++ -prototypes

CORE_C=			\
	..\av.c		\
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

ALL: $(PERLEXE) $(GLOBEXE) $(DYNALOADMODULES)

!IF "$(CFG)" ==""
CFG=Release
!ENDIF

modules.lib : $(DYNALOADER).c
	$(MAKE) -A -f modules.mak CFG="modules - Win32 $(CFG)"

$(GLOBEXE):
	$(MAKE) -f perlglob.mak CFG="perlglob - Win32 Release"

$(PERLLIB): $(CORE_C)
	$(MAKE) -f libperl.mak CFG="libperl - Win32 $(CFG)"

$(MINIPERL): $(PERLLIB)
	$(MAKE) -A -f miniperl.mak CFG="miniperl - Win32 $(CFG)"
	copy config.w32 ..\config.sh
	cd ..
	miniperl configpm
	cd win32
	if exist lib\* $(XCOPY) /e lib\*.* ..\lib\$(NULL)
	copy bin\test.bat ..\t

$(PERLDLL): $(MINIPERL) $(PERLLIB)
	$(MINIPERL) -w makedef.pl > perldll.def
	$(MAKE) -A -f perldll.mak CFG="perldll - Win32 $(CFG)"

$(PERLEXE): $(MINIPERL) modules.lib $(PERLDLL)
#	$(MINIPERL) makemain.pl $(STATICLINKMODUES) > perlmain.c
#	$(MINIPERL) makeperldef.pl $(STATICLINKMODUES) > perl.def
	$(MINIPERL) makeperldef.pl $(NULL) > perl.def
	copy runperl.c perlmain.c
	$(MAKE) -A -f perl.mak CFG="perl - Win32 $(CFG)"
	copy ..\_perl.exe $(PERLEXE)
	del ..\_perl.exe
	del ..\*.exp
	copy splittree.pl .. 
	$(MINIPERL) ..\splittree.pl "../LIB" "../LIB/auto"
	attrib -r ..\t\*.*
	copy test ..\t
	$(XCOPY) ..\*.h ..\lib\CORE\*.*
	$(XCOPY) $(PERLIMPLIB) ..\lib\CORE
	$(XCOPY) $(PERLLIB) ..\lib\CORE
	$(XCOPY) *.h ..\lib\CORE
	$(XCOPY) /S include ..\lib\CORE

$(DYNALOADER).c: $(EXTDIR)\DynaLoader\dl_win32.xs
	if not exist ..\lib\auto md ..\lib\auto
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) dl_win32.xs > $(*B).c
	cd ..\..\win32

$(EXTDIR)\DynaLoader\dl_win32.xs: dl_win32.xs
	copy dl_win32.xs $(EXTDIR)\DynaLoader\dl_win32.xs

$(SOCKET).c: $(SOCKET).xs
	if not exist ..\lib\auto\$(*B) md ..\lib\auto\$(*B)
	$(MINIPERL) genxsdef.pl $(*B) > $(*B).def
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) $(*B).xs > $(*B).c
	cd ..\..\win32

$(IO).c:  $(IO).xs
	if not exist ..\lib\auto\$(*B) md ..\lib\auto\$(*B)
	$(MINIPERL) genxsdef.pl $(*B) > $(*B).def
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	$(XCOPY) /s $(EXTDIR)\$(*B)\lib\*.* $(LIBDIR)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) $(*B).xs > $(*B).c
	cd ..\..\win32

$(SDBM_FILE).c:  $(SDBM_FILE).xs
	if not exist ..\lib\auto\$(*B) md ..\lib\auto\$(*B)
	$(MINIPERL) genxsdef.pl $(*B) > $(*B).def
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) -typemap ./typemap $(*B).xs > $(*B).c
	cd ..\..\win32

$(FCNTL).c:  $(FCNTL).xs
	if not exist ..\lib\auto\$(*B) md ..\lib\auto\$(*B)
	$(MINIPERL) genxsdef.pl $(*B) > $(*B).def
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) $(*B).xs > $(*B).c
	cd ..\..\win32

$(OPCODE).c:  $(OPCODE).xs
	if not exist ..\lib\auto\$(*B) md ..\lib\auto\$(*B)
	$(MINIPERL) genxsdef.pl $(*B) > $(*B).def
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	$(XCOPY) $(EXTDIR)\$(*B)\*.pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) $(*B).xs > $(*B).c
	cd ..\..\win32

$(SOCKET_DLL): $(SOCKET).c $(PERLDLL)
	$(MAKE) -f $(*B).mak CFG="$(*B) - Win32 $(CFG)"

$(IO_DLL): $(IO).c $(PERLDLL)
	$(MAKE) -f $(*B).mak CFG="$(*B) - Win32 $(CFG)"

$(SDBM_FILE_DLL): $(SDBM_FILE).c $(PERLDLL)
	$(MAKE) -f $(*B).mak CFG="$(*B) - Win32 $(CFG)"

$(FCNTL_DLL): $(FCNTL).c $(PERLDLL)
	$(MAKE) -f $(*B).mak CFG="$(*B) - Win32 $(CFG)"

$(OPCODE_DLL): $(OPCODE).c $(PERLDLL)
	$(MAKE) -f $(*B).mak CFG="$(*B) - Win32 $(CFG)"

doc: $(PERLEXE)
	$(PERLEXE) $(POD2HTML).PL
	$(PERLEXE) $(POD2MAN).PL
	$(PERLEXE) $(POD2LATEX).PL
	$(PERLEXE) $(POD2TEXT).PL
	$(PERLEXE) $(PL2BAT) $(POD2HTML)
	$(PERLEXE) $(PL2BAT) $(POD2MAN)
	$(PERLEXE) $(PL2BAT) $(POD2LATEX)
	$(PERLEXE) $(PL2BAT) $(POD2TEXT)
        cd $(PODDIR)
        $(PERLEXE) pod2html.bat *.pod
        cd ..\win32

utils: $(PERLEXE)
	cd ..\utils
	nmake PERL=$(MINIPERL)
	$(PERLEXE) ..\win32\$(PL2BAT) h2ph splain perlbug pl2pm c2ph \
			h2xs perldoc pstruct
	$(XCOPY) *.bat ..\win32\bin\*.*
	cd ..\win32

distclean:
	-del /f $(MINIPERL) $(PERLEXE) $(PERLDLL) $(GLOBEXE) $(PERLLIB) \
		$(PERLIMPLIB) ..\miniperl.lib modules.lib
	-del /f *.def
	-del /f $(SOCKET_DLL) $(IO_DLL) $(SDBM_FILE_DLL) $(FCNTL_DLL) \
		$(OPCODE_DLL)
	-del /f $(SOCKET).c $(IO).c $(SDBM_FILE).c $(FCNTL).c $(OPCODE).c \
		$(DYNALOADER).c
	-del /f $(PODDIR)\*.html
	-del /f $(PODDIR)\*.bat
	-rmdir /s /q ..\lib\auto
	-rmdir /s /q ..\lib\CORE
	-rmdir /s /q release
	-rmdir /s /q debug

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

inst_lib : 
	copy splittree.pl .. 
	$(MINIPERL) ..\splittree.pl "../LIB" "../LIB/auto"
	$(XCOPY) /e ..\lib $(INST_LIB)\*.*

test : all
	$(XCOPY) $(PERLEXE) ..\t\$(NULL)
	$(XCOPY) $(PERLDLL) ..\t\$(NULL)
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
        cd ..\t
        $(PERLEXE) test
	cd ..\win32
