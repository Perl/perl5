# Microsoft Developer Studio Generated NMAKE File, Format Version 4.20
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

!IF "$(CFG)" == ""
CFG=miniperl - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to miniperl - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "miniperl - Win32 Release" && "$(CFG)" !=\
 "miniperl - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "miniperl.mak" CFG="miniperl - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "miniperl - Win32 Release" (based on\
 "Win32 (x86) Console Application")
!MESSAGE "miniperl - Win32 Debug" (based on "Win32 (x86) Console Application")
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
# PROP Target_Last_Scanned "miniperl - Win32 Debug"
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "miniperl - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "miniperl"
# PROP BASE Intermediate_Dir "miniperl"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : "..\miniperl.exe"

CLEAN : 
	-@erase "$(INTDIR)\miniperlmain.obj"
	-@erase "$(INTDIR)\win32.obj"
	-@erase "$(INTDIR)\win32aux.obj"
	-@erase "$(INTDIR)\win32io.obj"
	-@erase "$(INTDIR)\win32sck.obj"
	-@erase "..\miniperl.exe"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /MT /W3 /Od /I "." /I ".\include" /I ".." /D "NDEBUG" /D "WIN32" /D "_CONSOLE" /D "PERLDLL" /YX /c
CPP_PROJ=/nologo /MT /W3 /Od /I "." /I ".\include" /I ".." /D "NDEBUG" /D\
 "WIN32" /D "_CONSOLE" /D "PERLDLL" /Fp"$(INTDIR)/miniperl.pch" /YX\
 /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=.\.
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/miniperl.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /machine:I386 /out:"../miniperl.exe"
# SUBTRACT LINK32 /incremental:yes /debug
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:console /incremental:no /pdb:"$(OUTDIR)/miniperl.pdb" /machine:I386\
 /out:"../miniperl.exe" 
LINK32_OBJS= \
	"$(INTDIR)\miniperlmain.obj" \
	"$(INTDIR)\win32.obj" \
	"$(INTDIR)\win32aux.obj" \
	"$(INTDIR)\win32io.obj" \
	"$(INTDIR)\win32sck.obj" \
	"..\libperl.lib"

"..\miniperl.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
    $(LINK32) @<<
  $(LINK32_FLAGS) $(LINK32_OBJS)
<<

!ELSEIF  "$(CFG)" == "miniperl - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "miniper0"
# PROP BASE Intermediate_Dir "miniper0"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : "..\miniperl.exe"

CLEAN : 
	-@erase "$(INTDIR)\miniperlmain.obj"
	-@erase "$(INTDIR)\vc40.idb"
	-@erase "$(INTDIR)\vc40.pdb"
	-@erase "$(INTDIR)\win32.obj"
	-@erase "$(INTDIR)\win32aux.obj"
	-@erase "$(INTDIR)\win32io.obj"
	-@erase "$(INTDIR)\win32sck.obj"
	-@erase "$(OUTDIR)\miniperl.pdb"
	-@erase "..\miniperl.exe"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /Gm /Zi /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /YX /c
# ADD CPP /nologo /MTd /W3 /Gm /Zi /Od /I "." /I ".\include" /I ".." /D "_DEBUG" /D "WIN32" /D "_CONSOLE" /D "PERLDLL" /YX /c
CPP_PROJ=/nologo /MTd /W3 /Gm /Zi /Od /I "." /I ".\include" /I ".." /D\
 "_DEBUG" /D "WIN32" /D "_CONSOLE" /D "PERLDLL" /Fp"$(INTDIR)/miniperl.pch" /YX\
 /Fo"$(INTDIR)/" /Fd"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=.\.
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/miniperl.bsc" 
BSC32_SBRS= \
	
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /debug /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo /subsystem:console /incremental:no /debug /machine:I386 /out:"../miniperl.exe"
LINK32_FLAGS=kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib\
 advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib /nologo\
 /subsystem:console /incremental:no /pdb:"$(OUTDIR)/miniperl.pdb" /debug\
 /machine:I386 /out:"../miniperl.exe" 
LINK32_OBJS= \
	"$(INTDIR)\miniperlmain.obj" \
	"$(INTDIR)\win32.obj" \
	"$(INTDIR)\win32aux.obj" \
	"$(INTDIR)\win32io.obj" \
	"$(INTDIR)\win32sck.obj" \
	"..\libperl.lib"

"..\miniperl.exe" : "$(OUTDIR)" $(DEF_FILE) $(LINK32_OBJS)
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

# Name "miniperl - Win32 Release"
# Name "miniperl - Win32 Debug"

!IF  "$(CFG)" == "miniperl - Win32 Release"

!ELSEIF  "$(CFG)" == "miniperl - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=..\miniperlmain.c
DEP_CPP_MINIP=\
	"..\av.h"\
	"..\cop.h"\
	"..\hv.h"\
	"..\mg.h"\
	"..\op.h"\
	"..\opcode.h"\
	"..\perl.h"\
	"..\perly.h"\
	"..\pp.h"\
	"..\proto.h"\
	"..\scope.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\EXTERN.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\nostdio.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\plan9\plan9ish.h"\
	".\..\regexp.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_MINIP=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\miniperlmain.obj" : $(SOURCE) $(DEP_CPP_MINIP) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=..\libperl.lib

!IF  "$(CFG)" == "miniperl - Win32 Release"

!ELSEIF  "$(CFG)" == "miniperl - Win32 Debug"

!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32.c
DEP_CPP_WIN32=\
	"..\av.h"\
	"..\cop.h"\
	"..\hv.h"\
	"..\mg.h"\
	"..\op.h"\
	"..\opcode.h"\
	"..\perl.h"\
	"..\perly.h"\
	"..\pp.h"\
	"..\proto.h"\
	"..\scope.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\nostdio.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\plan9\plan9ish.h"\
	".\..\regexp.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_WIN32=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\win32.obj" : $(SOURCE) $(DEP_CPP_WIN32) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32sck.c
DEP_CPP_WIN32S=\
	"..\av.h"\
	"..\cop.h"\
	"..\hv.h"\
	"..\mg.h"\
	"..\op.h"\
	"..\opcode.h"\
	"..\perl.h"\
	"..\perly.h"\
	"..\pp.h"\
	"..\proto.h"\
	"..\scope.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\nostdio.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\plan9\plan9ish.h"\
	".\..\regexp.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_WIN32S=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\win32sck.obj" : $(SOURCE) $(DEP_CPP_WIN32S) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32aux.c
DEP_CPP_WIN32A=\
	".\include\sys/socket.h"\
	

"$(INTDIR)\win32aux.obj" : $(SOURCE) $(DEP_CPP_WIN32A) "$(INTDIR)"


# End Source File
################################################################################
# Begin Source File

SOURCE=.\win32io.c
DEP_CPP_WIN32I=\
	".\include\sys/socket.h"\
	".\win32io.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	

"$(INTDIR)\win32io.obj" : $(SOURCE) $(DEP_CPP_WIN32I) "$(INTDIR)"


# End Source File
# End Target
# End Project
################################################################################
