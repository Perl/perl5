# Microsoft Developer Studio Generated NMAKE File, Format Version 4.20
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

!IF "$(CFG)" == ""
CFG=modules - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to modules - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "modules - Win32 Release" && "$(CFG)" !=\
 "modules - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "modules.mak" CFG="modules - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "modules - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "modules - Win32 Debug" (based on "Win32 (x86) Static Library")
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
# PROP Target_Last_Scanned "modules - Win32 Debug"
CPP=cl.exe

!IF  "$(CFG)" == "modules - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "modules_"
# PROP BASE Intermediate_Dir "modules_"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\Release
INTDIR=.\Release

ALL : ".\modules.lib"

CLEAN : 
	-@erase "$(INTDIR)\Dynaloader.obj"
	-@erase "$(INTDIR)\Fcntl.obj"
	-@erase "$(INTDIR)\hash.obj"
	-@erase "$(INTDIR)\IO.obj"
	-@erase "$(INTDIR)\Opcode.obj"
	-@erase "$(INTDIR)\pair.obj"
	-@erase "$(INTDIR)\sdbm.obj"
	-@erase "$(INTDIR)\SDBM_File.obj"
	-@erase "$(INTDIR)\Socket.obj"
	-@erase ".\modules.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MT /W3 /GX /O2 /I ".\include" /I "." /I ".." /D "NDEBUG" /D "WIN32" /D "_WINDOWS" /D "MSDOS" /YX /c
CPP_PROJ=/nologo /MT /W3 /GX /O2 /I ".\include" /I "." /I ".." /D "NDEBUG" /D\
 "WIN32" /D "_WINDOWS" /D "MSDOS" /Fp"$(INTDIR)/modules.pch" /YX /Fo"$(INTDIR)/"\
 /c 
CPP_OBJS=.\Release/
CPP_SBRS=.\.
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/modules.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"modules.lib"
LIB32_FLAGS=/nologo /out:"modules.lib" 
LIB32_OBJS= \
	"$(INTDIR)\Dynaloader.obj" \
	"$(INTDIR)\Fcntl.obj" \
	"$(INTDIR)\hash.obj" \
	"$(INTDIR)\IO.obj" \
	"$(INTDIR)\Opcode.obj" \
	"$(INTDIR)\pair.obj" \
	"$(INTDIR)\sdbm.obj" \
	"$(INTDIR)\SDBM_File.obj" \
	"$(INTDIR)\Socket.obj"

".\modules.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "modules0"
# PROP BASE Intermediate_Dir "modules0"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\Debug
INTDIR=.\Debug

ALL : ".\modules.lib"

CLEAN : 
	-@erase "$(INTDIR)\Dynaloader.obj"
	-@erase "$(INTDIR)\Fcntl.obj"
	-@erase "$(INTDIR)\hash.obj"
	-@erase "$(INTDIR)\IO.obj"
	-@erase "$(INTDIR)\Opcode.obj"
	-@erase "$(INTDIR)\pair.obj"
	-@erase "$(INTDIR)\sdbm.obj"
	-@erase "$(INTDIR)\SDBM_File.obj"
	-@erase "$(INTDIR)\Socket.obj"
	-@erase ".\modules.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

# ADD BASE CPP /nologo /W3 /GX /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MTd /W3 /GX /Z7 /Od /I ".\include" /I "." /I ".." /D "_DEBUG" /D "WIN32" /D "_WINDOWS" /D "MSDOS" /YX /c
CPP_PROJ=/nologo /MTd /W3 /GX /Z7 /Od /I ".\include" /I "." /I ".." /D "_DEBUG"\
 /D "WIN32" /D "_WINDOWS" /D "MSDOS" /Fp"$(INTDIR)/modules.pch" /YX\
 /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=.\.
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/modules.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo /out:"modules.lib"
LIB32_FLAGS=/nologo /out:"modules.lib" 
LIB32_OBJS= \
	"$(INTDIR)\Dynaloader.obj" \
	"$(INTDIR)\Fcntl.obj" \
	"$(INTDIR)\hash.obj" \
	"$(INTDIR)\IO.obj" \
	"$(INTDIR)\Opcode.obj" \
	"$(INTDIR)\pair.obj" \
	"$(INTDIR)\sdbm.obj" \
	"$(INTDIR)\SDBM_File.obj" \
	"$(INTDIR)\Socket.obj"

".\modules.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
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

# Name "modules - Win32 Release"
# Name "modules - Win32 Debug"

!IF  "$(CFG)" == "modules - Win32 Release"

!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=..\ext\DynaLoader\Dynaloader.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_DYNAL=\
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
	"..\XSUB.h"\
	".\..\ext\DynaLoader\dlutils.c"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_DYNAL=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\Dynaloader.obj" : $(SOURCE) $(DEP_CPP_DYNAL) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_DYNAL=\
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
	"..\XSUB.h"\
	".\..\ext\DynaLoader\dlutils.c"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_DYNAL=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\Dynaloader.obj" : $(SOURCE) $(DEP_CPP_DYNAL) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\Fcntl\Fcntl.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_FCNTL=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_FCNTL=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\Fcntl.obj" : $(SOURCE) $(DEP_CPP_FCNTL) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_FCNTL=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_FCNTL=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\Fcntl.obj" : $(SOURCE) $(DEP_CPP_FCNTL) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\Io\IO.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_IO_C4=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_IO_C4=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\IO.obj" : $(SOURCE) $(DEP_CPP_IO_C4) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_IO_C4=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_IO_C4=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\IO.obj" : $(SOURCE) $(DEP_CPP_IO_C4) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\Opcode\Opcode.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_OPCOD=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_OPCOD=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\Opcode.obj" : $(SOURCE) $(DEP_CPP_OPCOD) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_OPCOD=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_OPCOD=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\Opcode.obj" : $(SOURCE) $(DEP_CPP_OPCOD) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\SDBM_File.c
DEP_CPP_SDBM_=\
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
	"..\XSUB.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_SDBM_=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	

"$(INTDIR)\SDBM_File.obj" : $(SOURCE) $(DEP_CPP_SDBM_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\Socket\Socket.c
DEP_CPP_SOCKE=\
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
	"..\XSUB.h"\
	".\config.h"\
	".\EXTERN.h"\
	".\include\arpa/inet.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	
NODEP_CPP_SOCKE=\
	"..\os2ish.h"\
	"..\vmsish.h"\
	".\..\ext\Socket\sockadapt.h"\
	

"$(INTDIR)\Socket.obj" : $(SOURCE) $(DEP_CPP_SOCKE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\sdbm\sdbm.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_SDBM_C=\
	"..\ext\SDBM_File\sdbm\pair.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\ext\SDBM_File\sdbm\tune.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	

"$(INTDIR)\sdbm.obj" : $(SOURCE) $(DEP_CPP_SDBM_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_SDBM_C=\
	"..\ext\SDBM_File\sdbm\pair.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\ext\SDBM_File\sdbm\tune.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\sdbm.obj" : $(SOURCE) $(DEP_CPP_SDBM_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\sdbm\pair.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_PAIR_=\
	"..\ext\SDBM_File\sdbm\pair.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\ext\SDBM_File\sdbm\tune.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	

"$(INTDIR)\pair.obj" : $(SOURCE) $(DEP_CPP_PAIR_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_PAIR_=\
	"..\ext\SDBM_File\sdbm\pair.h"\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\..\ext\SDBM_File\sdbm\tune.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\pair.obj" : $(SOURCE) $(DEP_CPP_PAIR_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\ext\SDBM_File\sdbm\hash.c

!IF  "$(CFG)" == "modules - Win32 Release"

DEP_CPP_HASH_=\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	{$(INCLUDE)}"\sys\Stat.h"\
	{$(INCLUDE)}"\sys\Types.h"\
	

"$(INTDIR)\hash.obj" : $(SOURCE) $(DEP_CPP_HASH_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "modules - Win32 Debug"

DEP_CPP_HASH_=\
	".\..\ext\SDBM_File\sdbm\sdbm.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\hash.obj" : $(SOURCE) $(DEP_CPP_HASH_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
# End Target
# End Project
################################################################################
