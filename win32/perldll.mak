# Microsoft Developer Studio Generated NMAKE File, Format Version 4.20
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Dynamic-Link Library" 0x0102

!IF "$(CFG)" == ""
CFG=perldll - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to perldll - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "perldll - Win32 Release" && "$(CFG)" !=\
 "perldll - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "perldll.mak" CFG="perldll - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "perldll - Win32 Release" (based on\
 "Win32 (x86) Dynamic-Link Library")
!MESSAGE "perldll - Win32 Debug" (based on "Win32 (x86) Dynamic-Link Library")
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
# PROP Target_Last_Scanned "perldll - Win32 Debug"
CPP=cl.exe
RSC=rc.exe
MTL=mktyplib.exe

!IF  "$(CFG)" == "perldll - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "perldll_"
# PROP BASE Intermediate_Dir "perldll_"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "../"
# PROP Intermediate_Dir "release"
# PROP Target_Dir ""
OUTDIR=.\..
INTDIR=.\release

ALL : "$(OUTDIR)\perl.dll"

CLEAN : 
	-@erase "$(INTDIR)\perllib.obj"
	-@erase "$(INTDIR)\win32.obj"
	-@erase "$(INTDIR)\win32aux.obj"
	-@erase "$(INTDIR)\win32io.obj"
	-@erase "$(INTDIR)\win32sck.obj"
	-@erase "$(OUTDIR)\perl.dll"
	-@erase "$(OUTDIR)\perl.exp"
	-@erase "$(OUTDIR)\perl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

"$(INTDIR)" :
    if not exist "$(INTDIR)/$(NULL)" mkdir "$(INTDIR)"

# ADD BASE CPP /nologo /MT /W3 /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MT /W3 /O2 /I "." /I ".\include" /I ".." /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /D "PERLDLL" /YX /c
CPP_PROJ=/nologo /MT /W3 /O2 /I "." /I ".\include" /I ".." /D "NDEBUG" /D\
 "WIN32" /D "_WINDOWS" /D "PERLDLL" /Fp"$(INTDIR)/perldll.pch" /YX\
 /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\release/
CPP_SBRS=.\.
# ADD BASE MTL /nologo /D "NDEBUG" /win32
# ADD MTL /nologo /D "NDEBUG" /win32
MTL_PROJ=/nologo /D "NDEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/perldll.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /pdb:none /machine:I386 /out:"../perl.dll"
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /dll /pdb:none /machine:I386 /def:".\perldll.def"\
 /out:"$(OUTDIR)/perl.dll" /implib:"$(OUTDIR)/perl.lib" 
DEF_FILE= \
	".\perldll.def"
LINK32_OBJS= \
	"$(INTDIR)\perllib.obj" \
	"$(INTDIR)\win32.obj" \
	"$(INTDIR)\win32aux.obj" \
	"$(INTDIR)\win32io.obj" \
	"$(INTDIR)\win32sck.obj" \
	"..\libperl.lib" \
	".\modules.lib"

"$(OUTDIR)\perl.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "perldll - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "perldll0"
# PROP BASE Intermediate_Dir "perldll0"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "debug"
# PROP Intermediate_Dir "debug"
# PROP Target_Dir ""
OUTDIR=.\..
INTDIR=.\debug

ALL : "$(OUTDIR)\perl.dll"

CLEAN : 
	-@erase "$(INTDIR)\perllib.obj"
	-@erase "$(INTDIR)\vc40.idb"
	-@erase "$(INTDIR)\vc40.pdb"
	-@erase "$(INTDIR)\win32.obj"
	-@erase "$(INTDIR)\win32aux.obj"
	-@erase "$(INTDIR)\win32io.obj"
	-@erase "$(INTDIR)\win32sck.obj"
	-@erase "$(OUTDIR)\perl.exp"
	-@erase "$(OUTDIR)\perl.lib"
	-@erase "$(OUTDIR)\perl.pdb"
	-@erase "..\perl.dll"
	-@erase "..\perl.ilk"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /MTd /W3 /Gm /Zi /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MTd /W3 /Gm /Zi /Od /I "." /I ".\include" /I ".." /D "_DEBUG" /D "WIN32" /D "_WINDOWS" /D "PERLDLL" /YX /c
CPP_PROJ=/nologo /MTd /W3 /Gm /Zi /Od /I "." /I ".\include" /I ".." /D\
 "_DEBUG" /D "WIN32" /D "_WINDOWS" /D "PERLDLL" /Fp"$(INTDIR)/perldll.pch" /YX\
 /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\debug/
CPP_SBRS=.\.
# ADD BASE MTL /nologo /D "_DEBUG" /win32
# ADD MTL /nologo /D "_DEBUG" /win32
MTL_PROJ=/nologo /D "_DEBUG" /win32 
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/perldll.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:windows /dll /debug /machine:I386 /out:"../perl.dll"
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:windows /dll /incremental:yes /pdb:"$(OUTDIR)/perl.pdb" /debug\
 /machine:I386 /def:".\perldll.def" /out:"../perl.dll"\
 /implib:"$(OUTDIR)/perl.lib" 
DEF_FILE= \
	".\perldll.def"
LINK32_OBJS= \
	"$(INTDIR)\perllib.obj" \
	"$(INTDIR)\win32.obj" \
	"$(INTDIR)\win32aux.obj" \
	"$(INTDIR)\win32io.obj" \
	"$(INTDIR)\win32sck.obj" \
	"..\libperl.lib" \
	".\modules.lib"

"$(OUTDIR)\perl.dll" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "perldll - Win32 Release"
# Name "perldll - Win32 Debug"

!IF  "$(CFG)" == "perldll - Win32 Release"

!ELSEIF  "$(CFG)" == "perldll - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=.\perllib.c
DEP_CPP_PERLL=\
	"..\av.h"\
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
	"..\plan9\plan9ish.h"\
	"..\pp.h"\
	"..\proto.h"\
	"..\regexp.h"\
	"..\scope.h"\
	"..\sv.h"\
	"..\unixish.h"\
	"..\util.h"\
	".\config.h"\
	"..\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	
NODEP_CPP_PERLL=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\perllib.obj" : $(SOURCE) $(DEP_CPP_PERLL) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\perldll.def

!IF  "$(CFG)" == "perldll - Win32 Release"

!ELSEIF  "$(CFG)" == "perldll - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\libperl.lib

!IF  "$(CFG)" == "perldll - Win32 Release"

!ELSEIF  "$(CFG)" == "perldll - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32sck.c
DEP_CPP_WIN32=\
	"..\av.h"\
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
	"..\plan9\plan9ish.h"\
	"..\pp.h"\
	"..\proto.h"\
	"..\regexp.h"\
	"..\scope.h"\
	"..\sv.h"\
	"..\unixish.h"\
	"..\util.h"\
	".\config.h"\
	"..\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	
NODEP_CPP_WIN32=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\win32sck.obj" : $(SOURCE) $(DEP_CPP_WIN32) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32.c

!IF  "$(CFG)" == "perldll - Win32 Release"

DEP_CPP_WIN32_=\
	"..\embed.h"\
	"..\nostdio.h"\
	"..\perl.h"\
	"..\perlio.h"\
	"..\perlsdio.h"\
	"..\perlsfio.h"\
	".\config.h"\
	"..\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	

"$(INTDIR)\win32.obj" : $(SOURCE) $(DEP_CPP_WIN32_) "$(INTDIR)"


!ELSEIF  "$(CFG)" == "perldll - Win32 Debug"

DEP_CPP_WIN32_=\
	"..\perl.h"\
	"..\EXTERN.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	

"$(INTDIR)\win32.obj" : $(SOURCE) $(DEP_CPP_WIN32_) "$(INTDIR)"


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32aux.c
DEP_CPP_WIN32A=\
	".\include\sys/socket.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	

"$(INTDIR)\win32aux.obj" : $(SOURCE) $(DEP_CPP_WIN32A) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\modules.lib

!IF  "$(CFG)" == "perldll - Win32 Release"

!ELSEIF  "$(CFG)" == "perldll - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32io.c
DEP_CPP_WIN32I=\
	".\include\sys/socket.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\stat.h"\
	{$(INCLUDE)}"\sys\types.h"\
	

"$(INTDIR)\win32io.obj" : $(SOURCE) $(DEP_CPP_WIN32I) "$(INTDIR)"


# End Source File
# End Target
# End Project
################################################################################
