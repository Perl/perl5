# Microsoft Developer Studio Generated NMAKE File, Format Version 4.20
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Static Library" 0x0104

!IF "$(CFG)" == ""
CFG=libperl - Win32 Debug
!MESSAGE No configuration specified.  Defaulting to libperl - Win32 Debug.
!ENDIF 

!IF "$(CFG)" != "libperl - Win32 Release" && "$(CFG)" !=\
 "libperl - Win32 Debug"
!MESSAGE Invalid configuration "$(CFG)" specified.
!MESSAGE You can specify a configuration when running NMAKE on this makefile
!MESSAGE by defining the macro CFG on the command line.  For example:
!MESSAGE 
!MESSAGE NMAKE /f "libperl.mak" CFG="libperl - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "libperl - Win32 Release" (based on "Win32 (x86) Static Library")
!MESSAGE "libperl - Win32 Debug" (based on "Win32 (x86) Static Library")
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
# PROP Target_Last_Scanned "libperl - Win32 Debug"
CPP=cl.exe

!IF  "$(CFG)" == "libperl - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "../"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
OUTDIR=.\..
INTDIR=.\Release

ALL : "$(OUTDIR)\libperl.lib"

CLEAN : 
	-@erase "$(INTDIR)\av.obj"
	-@erase "$(INTDIR)\deb.obj"
	-@erase "$(INTDIR)\doio.obj"
	-@erase "$(INTDIR)\doop.obj"
	-@erase "$(INTDIR)\dump.obj"
	-@erase "$(INTDIR)\globals.obj"
	-@erase "$(INTDIR)\gv.obj"
	-@erase "$(INTDIR)\hv.obj"
	-@erase "$(INTDIR)\mg.obj"
	-@erase "$(INTDIR)\op.obj"
	-@erase "$(INTDIR)\perl.obj"
	-@erase "$(INTDIR)\perlio.obj"
	-@erase "$(INTDIR)\perly.obj"
	-@erase "$(INTDIR)\pp.obj"
	-@erase "$(INTDIR)\pp_ctl.obj"
	-@erase "$(INTDIR)\pp_hot.obj"
	-@erase "$(INTDIR)\pp_sys.obj"
	-@erase "$(INTDIR)\regcomp.obj"
	-@erase "$(INTDIR)\regexec.obj"
	-@erase "$(INTDIR)\run.obj"
	-@erase "$(INTDIR)\scope.obj"
	-@erase "$(INTDIR)\sv.obj"
	-@erase "$(INTDIR)\taint.obj"
	-@erase "$(INTDIR)\toke.obj"
	-@erase "$(INTDIR)\universal.obj"
	-@erase "$(INTDIR)\util.obj"
	-@erase "$(OUTDIR)\libperl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

"$(INTDIR)" :
    if not exist "$(INTDIR)/$(NULL)" mkdir "$(INTDIR)"

# ADD BASE CPP /nologo /W3 /O2 /D "WIN32" /D "NDEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MT /W3 /Od /I ".\include" /I ".." /I "." /D "WIN32" /D "NDEBUG" /D "PERLDLL" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MT /W3 /Od /I ".\include" /I ".." /I "." /D "WIN32" /D\
 "NDEBUG" /D "PERLDLL" /D "_WINDOWS" /Fp"$(INTDIR)/libperl.pch" /YX\
 /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Release/
CPP_SBRS=.\.
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/libperl.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo
LIB32_FLAGS=/nologo /out:"$(OUTDIR)/libperl.lib" 
LIB32_OBJS= \
	"$(INTDIR)\av.obj" \
	"$(INTDIR)\deb.obj" \
	"$(INTDIR)\doio.obj" \
	"$(INTDIR)\doop.obj" \
	"$(INTDIR)\dump.obj" \
	"$(INTDIR)\globals.obj" \
	"$(INTDIR)\gv.obj" \
	"$(INTDIR)\hv.obj" \
	"$(INTDIR)\mg.obj" \
	"$(INTDIR)\op.obj" \
	"$(INTDIR)\perl.obj" \
	"$(INTDIR)\perlio.obj" \
	"$(INTDIR)\perly.obj" \
	"$(INTDIR)\pp.obj" \
	"$(INTDIR)\pp_ctl.obj" \
	"$(INTDIR)\pp_hot.obj" \
	"$(INTDIR)\pp_sys.obj" \
	"$(INTDIR)\regcomp.obj" \
	"$(INTDIR)\regexec.obj" \
	"$(INTDIR)\run.obj" \
	"$(INTDIR)\scope.obj" \
	"$(INTDIR)\sv.obj" \
	"$(INTDIR)\taint.obj" \
	"$(INTDIR)\toke.obj" \
	"$(INTDIR)\universal.obj" \
	"$(INTDIR)\util.obj"

"$(OUTDIR)\libperl.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
    $(LIB32) @<<
  $(LIB32_FLAGS) $(DEF_FLAGS) $(LIB32_OBJS)
<<

!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 1
# PROP Output_Dir ".."
# PROP Intermediate_Dir "Debug"
# PROP Target_Dir ""
OUTDIR=.\..
INTDIR=.\Debug

ALL : "$(OUTDIR)\libperl.lib"

CLEAN : 
	-@erase "$(INTDIR)\av.obj"
	-@erase "$(INTDIR)\deb.obj"
	-@erase "$(INTDIR)\doio.obj"
	-@erase "$(INTDIR)\doop.obj"
	-@erase "$(INTDIR)\dump.obj"
	-@erase "$(INTDIR)\globals.obj"
	-@erase "$(INTDIR)\gv.obj"
	-@erase "$(INTDIR)\hv.obj"
	-@erase "$(INTDIR)\mg.obj"
	-@erase "$(INTDIR)\op.obj"
	-@erase "$(INTDIR)\perl.obj"
	-@erase "$(INTDIR)\perlio.obj"
	-@erase "$(INTDIR)\perly.obj"
	-@erase "$(INTDIR)\pp.obj"
	-@erase "$(INTDIR)\pp_ctl.obj"
	-@erase "$(INTDIR)\pp_hot.obj"
	-@erase "$(INTDIR)\pp_sys.obj"
	-@erase "$(INTDIR)\regcomp.obj"
	-@erase "$(INTDIR)\regexec.obj"
	-@erase "$(INTDIR)\run.obj"
	-@erase "$(INTDIR)\scope.obj"
	-@erase "$(INTDIR)\sv.obj"
	-@erase "$(INTDIR)\taint.obj"
	-@erase "$(INTDIR)\toke.obj"
	-@erase "$(INTDIR)\universal.obj"
	-@erase "$(INTDIR)\util.obj"
	-@erase "$(OUTDIR)\libperl.lib"

"$(OUTDIR)" :
    if not exist "$(OUTDIR)/$(NULL)" mkdir "$(OUTDIR)"

"$(INTDIR)" :
    if not exist "$(INTDIR)/$(NULL)" mkdir "$(INTDIR)"

# ADD BASE CPP /nologo /W3 /Z7 /Od /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
# ADD CPP /nologo /MT /W3 /Z7 /Od /I ".\include" /I ".." /I "." /D "WIN32" /D "_DEBUG" /D "_WINDOWS" /YX /c
CPP_PROJ=/nologo /MT /W3 /Z7 /Od /I ".\include" /I ".." /I "." /D "WIN32"\
/D "PERLDLL" /D "_DEBUG" /D "_WINDOWS" /Fp"$(INTDIR)/libperl.pch" /YX /Fo"$(INTDIR)/" /c 
CPP_OBJS=.\Debug/
CPP_SBRS=.\.
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
BSC32_FLAGS=/nologo /o"$(OUTDIR)/libperl.bsc" 
BSC32_SBRS= \
	
LIB32=link.exe -lib
# ADD BASE LIB32 /nologo
# ADD LIB32 /nologo
LIB32_FLAGS=/nologo /out:"$(OUTDIR)/libperl.lib" 
LIB32_OBJS= \
	"$(INTDIR)\av.obj" \
	"$(INTDIR)\deb.obj" \
	"$(INTDIR)\doio.obj" \
	"$(INTDIR)\doop.obj" \
	"$(INTDIR)\dump.obj" \
	"$(INTDIR)\globals.obj" \
	"$(INTDIR)\gv.obj" \
	"$(INTDIR)\hv.obj" \
	"$(INTDIR)\mg.obj" \
	"$(INTDIR)\op.obj" \
	"$(INTDIR)\perl.obj" \
	"$(INTDIR)\perlio.obj" \
	"$(INTDIR)\perly.obj" \
	"$(INTDIR)\pp.obj" \
	"$(INTDIR)\pp_ctl.obj" \
	"$(INTDIR)\pp_hot.obj" \
	"$(INTDIR)\pp_sys.obj" \
	"$(INTDIR)\regcomp.obj" \
	"$(INTDIR)\regexec.obj" \
	"$(INTDIR)\run.obj" \
	"$(INTDIR)\scope.obj" \
	"$(INTDIR)\sv.obj" \
	"$(INTDIR)\taint.obj" \
	"$(INTDIR)\toke.obj" \
	"$(INTDIR)\universal.obj" \
	"$(INTDIR)\util.obj"

"$(OUTDIR)\libperl.lib" : "$(OUTDIR)" $(DEF_FILE) $(LIB32_OBJS)
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

# Name "libperl - Win32 Release"
# Name "libperl - Win32 Debug"

!IF  "$(CFG)" == "libperl - Win32 Release"

!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

!ENDIF 

################################################################################
# Begin Source File

SOURCE=..\av.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_AV_C0=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\av.obj" : $(SOURCE) $(DEP_CPP_AV_C0) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_AV_C0=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_AV_C0=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\av.obj" : $(SOURCE) $(DEP_CPP_AV_C0) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\deb.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_DEB_C=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\deb.obj" : $(SOURCE) $(DEP_CPP_DEB_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_DEB_C=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_DEB_C=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\deb.obj" : $(SOURCE) $(DEP_CPP_DEB_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\doio.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_DOIO_=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\doio.obj" : $(SOURCE) $(DEP_CPP_DOIO_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_DOIO_=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_DOIO_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\doio.obj" : $(SOURCE) $(DEP_CPP_DOIO_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\doop.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_DOOP_=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\doop.obj" : $(SOURCE) $(DEP_CPP_DOOP_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_DOOP_=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_DOOP_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\doop.obj" : $(SOURCE) $(DEP_CPP_DOOP_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\dump.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_DUMP_=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\dump.obj" : $(SOURCE) $(DEP_CPP_DUMP_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_DUMP_=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_DUMP_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\dump.obj" : $(SOURCE) $(DEP_CPP_DUMP_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\globals.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_GLOBA=\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\INTERN.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_GLOBA=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\globals.obj" : $(SOURCE) $(DEP_CPP_GLOBA) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_GLOBA=\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\INTERN.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_GLOBA=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\globals.obj" : $(SOURCE) $(DEP_CPP_GLOBA) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\gv.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_GV_Cc=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\gv.obj" : $(SOURCE) $(DEP_CPP_GV_Cc) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_GV_Cc=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_GV_Cc=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\gv.obj" : $(SOURCE) $(DEP_CPP_GV_Cc) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\hv.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_HV_Ce=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\hv.obj" : $(SOURCE) $(DEP_CPP_HV_Ce) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_HV_Ce=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_HV_Ce=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\hv.obj" : $(SOURCE) $(DEP_CPP_HV_Ce) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\mg.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_MG_C10=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\mg.obj" : $(SOURCE) $(DEP_CPP_MG_C10) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_MG_C10=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_MG_C10=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\mg.obj" : $(SOURCE) $(DEP_CPP_MG_C10) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\op.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_OP_C12=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\op.obj" : $(SOURCE) $(DEP_CPP_OP_C12) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_OP_C12=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_OP_C12=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\op.obj" : $(SOURCE) $(DEP_CPP_OP_C12) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\perl.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PERL_=\
	"..\EXTERN.h"\
	".\..\patchlevel.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\perl.obj" : $(SOURCE) $(DEP_CPP_PERL_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PERL_=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\patchlevel.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PERL_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\perl.obj" : $(SOURCE) $(DEP_CPP_PERL_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\perlio.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PERLI=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\perlio.obj" : $(SOURCE) $(DEP_CPP_PERLI) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PERLI=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PERLI=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\perlio.obj" : $(SOURCE) $(DEP_CPP_PERLI) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\perly.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PERLY=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\perly.obj" : $(SOURCE) $(DEP_CPP_PERLY) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PERLY=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PERLY=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\perly.obj" : $(SOURCE) $(DEP_CPP_PERLY) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\pp.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PP_C1a=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\pp.obj" : $(SOURCE) $(DEP_CPP_PP_C1a) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PP_C1a=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PP_C1a=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\pp.obj" : $(SOURCE) $(DEP_CPP_PP_C1a) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\pp_ctl.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PP_CT=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\pp_ctl.obj" : $(SOURCE) $(DEP_CPP_PP_CT) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PP_CT=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PP_CT=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\pp_ctl.obj" : $(SOURCE) $(DEP_CPP_PP_CT) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\pp_hot.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PP_HO=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\pp_hot.obj" : $(SOURCE) $(DEP_CPP_PP_HO) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PP_HO=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PP_HO=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\pp_hot.obj" : $(SOURCE) $(DEP_CPP_PP_HO) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\pp_sys.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_PP_SY=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\pp_sys.obj" : $(SOURCE) $(DEP_CPP_PP_SY) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_PP_SY=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_PP_SY=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\pp_sys.obj" : $(SOURCE) $(DEP_CPP_PP_SY) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\regcomp.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_REGCO=\
	"..\EXTERN.h"\
	".\..\INTERN.h"\
	".\..\perl.h"\
	".\..\regcomp.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\regcomp.obj" : $(SOURCE) $(DEP_CPP_REGCO) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_REGCO=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\INTERN.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regcomp.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_REGCO=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\regcomp.obj" : $(SOURCE) $(DEP_CPP_REGCO) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\regexec.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_REGEX=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\..\regcomp.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\regexec.obj" : $(SOURCE) $(DEP_CPP_REGEX) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_REGEX=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regcomp.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_REGEX=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\regexec.obj" : $(SOURCE) $(DEP_CPP_REGEX) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\run.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_RUN_C=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\run.obj" : $(SOURCE) $(DEP_CPP_RUN_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_RUN_C=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_RUN_C=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\run.obj" : $(SOURCE) $(DEP_CPP_RUN_C) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\scope.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_SCOPE=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\scope.obj" : $(SOURCE) $(DEP_CPP_SCOPE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_SCOPE=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_SCOPE=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\scope.obj" : $(SOURCE) $(DEP_CPP_SCOPE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\sv.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_SV_C2a=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\sv.obj" : $(SOURCE) $(DEP_CPP_SV_C2a) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_SV_C2a=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_SV_C2a=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\sv.obj" : $(SOURCE) $(DEP_CPP_SV_C2a) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\taint.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_TAINT=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\taint.obj" : $(SOURCE) $(DEP_CPP_TAINT) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_TAINT=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_TAINT=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\taint.obj" : $(SOURCE) $(DEP_CPP_TAINT) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\toke.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_TOKE_=\
	"..\EXTERN.h"\
	".\..\keywords.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\toke.obj" : $(SOURCE) $(DEP_CPP_TOKE_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_TOKE_=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\keywords.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_TOKE_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\toke.obj" : $(SOURCE) $(DEP_CPP_TOKE_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\universal.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_UNIVE=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\..\XSUB.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\universal.obj" : $(SOURCE) $(DEP_CPP_UNIVE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_UNIVE=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\..\XSUB.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_UNIVE=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\universal.obj" : $(SOURCE) $(DEP_CPP_UNIVE) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
################################################################################
# Begin Source File

SOURCE=..\util.c

!IF  "$(CFG)" == "libperl - Win32 Release"

DEP_CPP_UTIL_=\
	"..\EXTERN.h"\
	".\..\perl.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	

"$(INTDIR)\util.obj" : $(SOURCE) $(DEP_CPP_UTIL_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ELSEIF  "$(CFG)" == "libperl - Win32 Debug"

DEP_CPP_UTIL_=\
	"..\EXTERN.h"\
	".\..\av.h"\
	".\..\cop.h"\
	".\..\cv.h"\
	".\..\dosish.h"\
	".\..\embed.h"\
	".\..\form.h"\
	".\..\gv.h"\
	".\..\handy.h"\
	".\..\hv.h"\
	".\..\mg.h"\
	".\..\nostdio.h"\
	".\..\op.h"\
	".\..\opcode.h"\
	".\..\perl.h"\
	".\..\perlio.h"\
	".\..\perlsdio.h"\
	".\..\perlsfio.h"\
	".\..\perly.h"\
	".\..\plan9\plan9ish.h"\
	".\..\pp.h"\
	".\..\proto.h"\
	".\..\regexp.h"\
	".\..\scope.h"\
	".\..\sv.h"\
	".\..\unixish.h"\
	".\..\util.h"\
	".\config.h"\
	".\include\dirent.h"\
	".\include\netdb.h"\
	".\include\sys/socket.h"\
	".\win32.h"\
	".\win32io.h"\
	".\win32iop.h"\
	"$(INCLUDE)\Sys\Stat.h"\
	"$(INCLUDE)\Sys\Types.h"\
	
NODEP_CPP_UTIL_=\
	".\..\os2ish.h"\
	".\..\vmsish.h"\
	

"$(INTDIR)\util.obj" : $(SOURCE) $(DEP_CPP_UTIL_) "$(INTDIR)"
   $(CPP) $(CPP_PROJ) $(SOURCE)


!ENDIF 

# End Source File
# End Target
# End Project
################################################################################
