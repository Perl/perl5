# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

!IF "$(CFG)" == ""
CFG=Socket - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to Socket - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "Socket - Win32 Release" && "$(CFG)" != "Socket - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "Socket.mak" CFG="Socket - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "Socket - Win32 Release" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE "Socket - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
!MESSAGE 
!ERROR An invalid configuration is specified.
!ENDIF 

!IF "$(OS)" == "Windows_NT"
NULL=
!ELSE 
NULL=nul
!ENDIF 
################################################################################
# Begin Project
# PROP Target_Last_Scanned "Socket - Win32 Debug"
CPP=cl.exe
RSC=rc.exe
MTL=mktyplib.exe

!IF  "$(CFG)" == "Socket - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Socket__"
# PROP BASE Intermediate_Dir "Socket__"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "release"
# PROP Intermediate_Dir "release"
# PROP Target_Dir ""
OUTDIR=.\release
INTDIR=.\release

ALL : "$(OUTDIR)\Socket.dll"

CLEAN : 
	-@erase "..\lib\auto\Socket\Socket.dll"
	-@erase ".\release\Socket.obj"
	-@erase ".\release\Socket.lib"
	-@erase ".\release\Socket.exp"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /MT /W3 /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MT /W3 /O2 /I ".\include" /I "." /I ".." /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MT /W3 /O2 /I ".\include" /I "." /I ".." /D "WIN32" /D\
 "NDEBUG" /D "_WINDOWS" /Fp"$(INTDIR)/Socket.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/Socket.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /machine:I386 /out:"..\lib\auto\Socket\Socket.dll"
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /dll /incremental:no /pdb:"$(OUTDIR)/Socket.pdb"\
 /machine:I386 /def:".\Socket.def" /out:"..\lib\auto\Socket\Socket.dll"\
 /implib:"$(OUTDIR)/Socket.lib" 
DEF_FILE= \
	".\Socket.def"
LINK32_OBJS= \
	"$(INTDIR)/Socket.obj" \
	"..\perl.lib"

"$(OUTDIR)\Socket.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "Socket - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Socket_0"
# PROP BASE Intermediate_Dir "Socket_0"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "debug"
# PROP Intermediate_Dir "debug"
# PROP Target_Dir ""
OUTDIR=.\debug
INTDIR=.\debug

ALL : "$(OUTDIR)\Socket.dll"

CLEAN : 
	-@erase ".\debug\vc40.pdb"
	-@erase ".\debug\vc40.idb"
	-@erase "..\lib\auto\Socket\Socket.dll"
	-@erase ".\debug\Socket.obj"
	-@erase ".\debug\Socket.ilk"
	-@erase ".\debug\Socket.lib"
	-@erase ".\debug\Socket.exp"
	-@erase ".\debug\Socket.pdb"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /MTd /W3 /Gm /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MTd /W3 /Gm /Zi /Od /I ".\include" /I "." /I ".." /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MTd /W3 /Gm /Zi /Od /I ".\include" /I "." /I ".." /D\
 "WIN32" /D "_DEBUG" /D "_WINDOWS" /Fp"$(INTDIR)/Socket.pch" /YX /Fo"$(INTDIR)/"\
 /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\debug/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/Socket.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /debug /machine:I386
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /dll /incremental:no /pdb:"$(OUTDIR)/Socket.pdb" /debug\
 /machine:I386 /def:".\Socket.def" /out:"..\lib\auto\Socket\Socket.dll"\
 /implib:"$(OUTDIR)/Socket.lib" 
DEF_FILE= \
	".\Socket.def"
LINK32_OBJS= \
	"$(INTDIR)/Socket.obj" \
	"..\perl.lib"

"$(OUTDIR)\Socket.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ENDIF 

.c{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_OBJS)}.obj:
   $(CPP) $(CPP_PROJ) $<  

.c{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cpp{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

.cxx{$(CPP_SBRS)}.sbr:
   $(CPP) $(CPP_PROJ) $<  

################################################################################
# Begin Target

# Name "Socket - Win32 Release"
# Name "Socket - Win32 Debug"

!IF  "$(CFG)" == "Socket - Win32 Release"

!ELSEIF  "$(CFG)" == "Socket - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=..\ext\Socket\Socket.c
DEP_CPP_SOCKE=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\..\XSUB.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	".\include\sys/socket.h"\
	".\include\netdb.h"\
	".\include\arpa/inet.h"\
	".\..\embed.h"\
	".\config.h"\
	".\..\perlio.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	".\include\dirent.h"\
	".\..\handy.h"\
	".\..\dosish.h"\
	".\..\plan9\plan9ish.h"\
	".\..\unixish.h"\
	".\..\regexp.h"\
	".\..\sv.h"\
	".\..\util.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\cv.h"\
	".\..\opcode.h"\
	".\..\op.h"\
	".\..\cop.h"\
	".\..\av.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\scope.h"\
	".\..\perly.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\win32.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\nostdio.h"\
	
NODEP_CPP_SOCKE=\
	".\..\ext\Socket\sockadapt.h"\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\Socket.obj" : $(SOURCE) $(DEP_CPP_SOCKE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=..\perl.lib

!IF  "$(CFG)" == "Socket - Win32 Release"

!ELSEIF  "$(CFG)" == "Socket - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\Socket.def

!IF  "$(CFG)" == "Socket - Win32 Release"

!ELSEIF  "$(CFG)" == "Socket - Win32 Debug"

!ENDIF 

# End Source File
# End Target
# End Project
################################################################################
