
LIBDIR=..\..\lib
EXTDIR=..\ext
EXTUTILSDIR=$(LIBDIR)\extutils
XSUBPP=..\..\miniperl $(EXTUTILSDIR)\xsubpp -C++ -prototypes
AUTOSPLIT=..\..\miniperl ..\..\win32\autosplit.pl
DEST=..\

EXTENSIONS=DynaLoader Socket IO Fcntl Opcode SDBM_File
#STATICLINKMODUES=DynaLoader Socket Fcntl Opcode SDBM_File
STATICLINKMODUES=
#DYNALOADMODULES=IO.dll 
DYNALOADMODULES=Socket.dll Fcntl.dll Opcode.dll SDBM_File.dll IO.dll

ALL: perl

!IF "$(CFG)" ==""
CFG=Release
!ENDIF

modules : $(EXTENSIONS)
	nmake -A -f modules.mak CFG="modules - Win32 $(CFG)"

perlglob.exe:
	nmake -f perlglob.mak CFG="perlglob - Win32 Release"

libperl.lib:
	attrib -r ..\*.h
	copy dosish.h ..
	copy EXTERN.h ..
	nmake -f libperl.mak CFG="libperl - Win32 $(CFG)"

miniperl.exe: libperl.lib 
	nmake -A -f miniperl.mak CFG="miniperl - Win32 $(CFG)"
	copy config.w32 ..\config.sh
	cd ..
	miniperl configpm
	cd win32
	if exist lib\* xcopy lib\*.* ..\lib\ /s/e
	copy bin\test.bat ..\t

perldll: miniperl.exe libperl.lib 
	..\miniperl -w makedef.pl > perldll.def
	nmake -A -f perldll.mak CFG="perldll - Win32 $(CFG)"

dynamodules: $(DYNALOADMODULES)

perl: miniperl.exe modules perldll perlglob.exe dynamodules 
	..\miniperl makemain.pl $(STATICLINKMODUES) > perlmain.c
	..\miniperl makeperldef.pl $(STATICLINKMODUES) > perl.def
	copy runperl.c perlmain.c
	nmake -A -f perl.mak CFG="perl - Win32 $(CFG)"
	copy ..\_perl.exe ..\perl.exe
	del ..\_perl.exe
	del ..\*.exp
	copy splittree.pl .. 
	..\miniperl ..\splittree.pl "../LIB" "../LIB/auto"
	attrib -r ..\t\*.*
	copy test ..\t
	xcopy ..\perl.h ..\lib\CORE\*.*

DynaLoader:
	md ..\lib\auto
	cd $(EXTDIR)\$*
	copy ..\..\win32\dl_win32.xs .
	copy $*.pm $(LIBDIR)
	$(XSUBPP) dl_win32.xs > $*.c
	cd ..\..\win32

Socket: 
	md ..\lib\auto\$*
	..\miniperl genxsdef.pl $* > $*.def
	cd $(EXTDIR)\$*
	copy $*.pm $(LIBDIR)
	$(XSUBPP) $*.xs > $*.c
	cd ..\..\win32

Socket.dll:
	nmake -f $*.mak CFG="$* - Win32 $(CFG)"

IO: 
	md ..\lib\auto\$*
	..\miniperl genxsdef.pl $* > $*.def
	cd $(EXTDIR)\$*
	copy $*.pm $(LIBDIR)
	xcopy lib\*.* $(LIBDIR) /s
	$(XSUBPP) $*.xs > $*.c
	cd ..\..\win32

IO.dll:
	nmake -f $*.mak CFG="$* - Win32 $(CFG)"

SDBM_File: 
	md ..\lib\auto\$*
	..\miniperl genxsdef.pl $* > $*.def
	cd $(EXTDIR)\$*
	copy $*.pm $(LIBDIR)
	$(XSUBPP) -typemap ./typemap $*.xs > $*.c
	cd ..\..\win32

SDBM_File.dll:
	nmake -f $*.mak CFG="$* - Win32 $(CFG)"

Fcntl: 
	md ..\lib\auto\$*
	..\miniperl genxsdef.pl $* > $*.def
	cd $(EXTDIR)\$*
	copy $*.pm $(LIBDIR)
	$(XSUBPP) $*.xs > $*.c
	cd ..\..\win32

Fcntl.dll:
	nmake -f $*.mak CFG="$* - Win32 $(CFG)"

Opcode: 
	md ..\lib\auto\$*
	..\miniperl genxsdef.pl $* > $*.def
	cd $(EXTDIR)\$*
	xcopy *.pm $(LIBDIR)
	$(XSUBPP) $*.xs > $*.c
	cd ..\..\win32

Opcode.dll:
	nmake -f $*.mak CFG="$* - Win32 $(CFG)"


