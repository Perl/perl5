# Microsoft Developer Studio Generated NMAKE File, Format Version 4.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

!IF "$(CFG)" == ""
CFG=SDBM_File - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to SDBM_File - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "SDBM_File - Win32 Release" && "$(CFG)" !=\
 "SDBM_File - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "SDBM_File.mak" CFG="SDBM_File - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "SDBM_File - Win32 Release" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE "SDBM_File - Win32 Debug" (based on\
 "Win32 (x86) Dynamic-Link Library")
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
# PROP Target_Last_Scanned "SDBM_File - Win32 Debug"
CPP=cl.exe
RSC=rc.exe
MTL=mktyplib.exe

!IF  "$(CFG)" == "SDBM_File - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "SDBM_Fil"
# PROP BASE Intermediate_Dir "SDBM_Fil"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "$(OUTDIR)\SDBM_File.dll"

CLEAN : 
	-@erase "..\lib\auto\SDBM_File\SDBM_File.dll"
	-@erase ".\Release\sdbm.obj"
	-@erase ".\Release\pair.obj"
	-@erase ".\Release\hash.obj"
	-@erase ".\Release\SDBM_File.obj"
	-@erase ".\Release\SDBM_File.lib"
	-@erase ".\Release\SDBM_File.exp"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /MT /W3 /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /c
# ADD CPP /nologo /MT /W3 /O2 /I ".\include" /I "." /I ".." /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /D "MSDOS" /c
CPP_PROJ=/nologo /MT /W3 /O2 /I ".\include" /I "." /I ".." /D "NDEBUG" /D\
 "WIN32" /D "_WINDOWS" /D "MSDOS" \
 /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/SDBM_File.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /pdb:none /machine:I386 /out:"../lib/auto/SDBM_File/SDBM_File.dll"
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /dll /pdb:none /machine:I386 /def:".\SDBM_File.def"\
 /out:"../lib/auto/SDBM_File/SDBM_File.dll" /implib:"$(OUTDIR)/SDBM_File.lib" 
DEF_FILE= \
	".\SDBM_File.def"
LINK32_OBJS= \
	"$(INTDIR)/sdbm.obj" \
	"$(INTDIR)/pair.obj" \
	"$(INTDIR)/hash.obj" \
	"$(INTDIR)/SDBM_File.obj" \
	"..\perl.lib"

"$(OUTDIR)\SDBM_File.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "SDBM_File - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "$(OUTDIR)\SDBM_File.dll"

CLEAN : 
	-@erase ".\Debug\vc40.pdb"
	-@erase ".\Debug\vc40.idb"
	-@erase "..\lib\auto\SDBM_File\SDBM_File.dll"
	-@erase ".\Debug\hash.obj"
	-@erase ".\Debug\pair.obj"
	-@erase ".\Debug\SDBM_File.obj"
	-@erase ".\Debug\sdbm.obj"
	-@erase ".\Debug\SDBM_File.lib"
	-@erase ".\Debug\SDBM_File.exp"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /MTd /W3 /Gm /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /c
# ADD CPP /nologo /MTd /W3 /Gm /Zi /Od /I ".\include" /I "." /I ".." /D "_DEBUG" /D "WIN32" /D "_WINDOWS" /D "MSDOS" /c
CPP_PROJ=/nologo /MTd /W3 /Gm /Zi /Od /I ".\include" /I "." /I ".." /D\
 "_DEBUG" /D "WIN32" /D "_WINDOWS" /D "MSDOS" \
 /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/SDBM_File.bsc" 
BSC32_SBRS=
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /pdb:none /debug /machine:I386 /out:"../lib/auto/SDBM_File/SDBM_File.dll"
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /dll /pdb:none /debug /machine:I386 /def:".\SDBM_File.def"\
 /out:"../lib/auto/SDBM_File/SDBM_File.dll" /implib:"$(OUTDIR)/SDBM_File.lib" 
DEF_FILE= \
	".\SDBM_File.def"
LINK32_OBJS= \
	"$(INTDIR)/hash.obj" \
	"$(INTDIR)/pair.obj" \
	"$(INTDIR)/SDBM_File.obj" \
	"$(INTDIR)/sdbm.obj" \
	"..\perl.lib"

"$(OUTDIR)\SDBM_File.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "SDBM_File - Win32 Release"
# Name "SDBM_File - Win32 Debug"

!IF  "$(CFG)" == "SDBM_File - Win32 Release"

!ELSEIF  "$(CFG)" == "SDBM_File - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\SDBM_File.c
DEP_CPP_SDBM_=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\..\XSUB.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\embed.h"\
	".\config.h"\
	{$(INCLUDE)}"\sys\Types.h"\
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
	".\include\sys/socket.h"\
	".\include\netdb.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\nostdio.h"\
	
NODEP_CPP_SDBM_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

!IF  "$(CFG)" == "SDBM_File - Win32 Release"


"$(INTDIR)\SDBM_File.obj" : $(SOURCE) $(DEP_CPP_SDBM_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "SDBM_File - Win32 Debug"


"$(INTDIR)\SDBM_File.obj" : $(SOURCE) $(DEP_CPP_SDBM_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\sdbm\sdbm.c
DEP_CPP_SDBM_C=\
	".\config.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\ext\SDBM_File\sdbm\tune.h"\
	".\win32.h"\
	".\include\dirent.h"\
	".\include\sys/socket.h"\
	".\include\netdb.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	

"$(INTDIR)\sdbm.obj" : $(SOURCE) $(DEP_CPP_SDBM_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\sdbm\pair.c
DEP_CPP_PAIR_=\
	".\config.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\ext\SDBM_File\sdbm\tune.h"\
	".\win32.h"\
	".\include\dirent.h"\
	".\include\sys/socket.h"\
	".\include\netdb.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	

"$(INTDIR)\pair.obj" : $(SOURCE) $(DEP_CPP_PAIR_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\sdbm\hash.c
DEP_CPP_HASH_=\
	".\config.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\win32.h"\
	".\include\dirent.h"\
	".\include\sys/socket.h"\
	".\include\netdb.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	

"$(INTDIR)\hash.obj" : $(SOURCE) $(DEP_CPP_HASH_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=.\SDBM_File.def

!IF  "$(CFG)" == "SDBM_File - Win32 Release"

!ELSEIF  "$(CFG)" == "SDBM_File - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\perl.lib

!IF  "$(CFG)" == "SDBM_File - Win32 Release"

!ELSEIF  "$(CFG)" == "SDBM_File - Win32 Debug"

!ENDIF 

# End Source File
# End Target
# End Project
################################################################################
