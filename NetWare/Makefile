##
## Makefile to build Perl on NetWare using Microsoft NMAKE and Watcom tools
##
## This will build perl.nlm, perl.lib and extensions called NLPs
##

##
## Please read README.netware before starting
##

##
## Build configuration.  Edit the values below to suit your needs.
##

## This file is created by using the makefile that creates Windows Perl as the reference
## Author: sgp
## Date Created: 13th July 2000
## Date Modified: 30th June 2001

# Name of the NLM
NLM_NAME		= perl.nlm
NLM_NAME8		= Perl

MAKE_ACTION		= Build

# Flags
DBG_FLAG	= -DDEBUGON

NW_FLAGS	= -DNETWARE -DNLM_PLATFORM -DNETDB_USE_INTERNET

REL_DIR	= Release
DEB_DIR = Debug

!ifndef MAKE_TYPE
#MAKE_TYPE = Release
!message "Run bat\buildtype.bat to set the build type before continuing.\n"
!error
!endif																#!ifndef MAKE_TYPE

!ifdef USE_MPK
MPKFLAGS	= -DMPK_ON -DIAPX386
MPKMESSAGE = MPK Build...
XDCTOOL	= mpkxdc
!ifndef MPKBASE
#MPKBASE			= p:\mpk
!message "Run bat\setnwbld.bat to set the NetWare MPK SDK before continuing.\n"
!error
!endif																#ifndef MPKBASE
NLM_INCLUDE_MP		= $(MPKBASE)\include
MPKTOOL = $(MPKBASE)\$(XDCTOOL)
!else
MPKMESSAGE = Non MPK Build...
NLM_INCLUDE_MP =
MPKTOOL = 
!endif																#ifdef USE_MPK

!ifndef NLMSDKBASE
#NLMSDKBASE		= P:\ndk\nwsdk
!message "Run bat\setnwbld.bat to set the NetWare SDK before continuing.\n"
!error
!endif																#ifndef NLMSDKBASE
NLMIMPORTS      = $(NLMSDKBASE)\imports

!ifdef WATCOM
C_COMPILER		= wcc386
CPP_COMPILER	= wpp386
NLM_LINK		= wlink
NLM_LIB			= lib386
TOOL_HEADERS	= $(WATCOM)\H;$(WATCOM)\H\NT
TOOL_PATH		= $(WATCOM)\BINNT;$(WATCOM)\BINW
CCFLAGS			= /zp1 /5s /w1 /zq /ms /otexanih /fpi
COMPILER_FLAG	= -DWATCOM
ERROR_FLAG		= -Fr
!if "$(MAKE_TYPE)"=="Debug"
BLDDIR          = $(DEB_DIR)
BLDMESG			= Debug version,
!ifdef USE_D2
BS_CFLAGS	= /od /d2 /en /st /hc -DDEBUGGING -DUSE_D2 $(DBG_FLAG)
BLDMESG		= $(BLDMESG) Using /d2 option
!else
BS_CFLAGS	= /od /d1 /en /st /hc -DDEBUGGING $(DBG_FLAG)
BLDMESG		= $(BLDMESG) Using /d1 option
!endif																#!ifdef USE_D2	
! else
BLDDIR          = $(REL_DIR)
BLDMESG		= Release version
BS_CFLAGS	= 
!endif																#if "$(MAKE_TYPE)"=="Debug"
!else																#ifdef WATCOM
!ifdef CODEWARRIOR
# Here comes the CW tools - TO BE FILLED TO BUILD WITH CW -
C_COMPILER		= 
CPP_COMPILER	= 
NLM_LINK		= 
NLM_LIB			= 
TOOL_HEADERS	= 
TOOL_PATH		= 
CCFLAGS			= 
COMPILER_FLAG	= 
ERROR_FLAG		=
# Debug flags comes here - Not mandatory - required only for debug build
!if "$(MAKE_TYPE)"=="Debug"
BLDDIR          = $(DEB_DIR)
BLDMESG			= Debug version,
!ifdef USE_D2
BS_CFLAGS	= 
BLDMESG		= $(BLDMESG) Using /d2 option
!else
BS_CFLAGS	= 
BLDMESG		= $(BLDMESG) Using /d1 option
!endif																#!ifdef USE_D2	
! else
BLDDIR      = $(REL_DIR)
BLDMESG		= Release version
BS_CFLAGS	= 
!endif																#if "$(MAKE_TYPE)"=="Debug"
!else																#!ifdef CODEWARRIOR
!message "Tools base directory is not defined. Run bat\setnwbld.bat before proceeding"
!error
Run bat\setnwbld.bat
!endif																#!ifdef CODEWARRIOR
!endif																#ifdef WATCOM

ADD_LOCDEFS =	-DPERL_CORE

NLM_INCLUDE			= -I$(NLMSDKBASE)\include
NLM_INCLUDE_NLM		= -I$(NLMSDKBASE)\include\nlm
NLM_INCLUDE_NLM_SYS = -I$(NLMSDKBASE)\include\nlm\sys
INCLUDE_NW          = -I.\include
INC_PREV			= -I..
INC_THIS			= -I.\

NLM_INCLUDE_PATH = $(NLMSDKBASE)\include\nlm;$(NLMSDKBASE)\include;$(NLMSDKBASE)\include\nlm\sys;$(NLM_INCLUDE_MP);$(TOOL_HEADERS)

INCLUDE = $(NLM_INCLUDE_PATH)

PATH = $(PATH);$(TOOL_PATH)
 
NLM_INCLUDES	=	-I$(COREDIR) $(INCLUDE_NW) $(INC_THIS) $(INC_PREV)

COMPLER_FLAGS	=  $(CCFLAGS) $(BS_CFLAGS) $(ADD_BUILDOPT) $(NW_FLAGS) $(COMPILER_FLAG) $(MPKFLAGS)

# Source file list
NW_H_FILES			=	\
						.\iperlhost.h	\
						.\interface.h	\
						.\netware.h \
						.\nw5iop.h	\
						.\nw5sck.h	\
						.\nwpipe.h	\
						.\nwplglob.h	\
						.\nwtinfo.h	\
						.\nwutil.h	\
						.\nwperlsys.h	\

NW_HOST_H_FILES		=	\
						.\iperlhost.h	\
						.\interface.h	\
						.\netware.h	\
						.\nw5sck.h	\
						.\nwperlsys.h	\

CLIB_H_FILES		=	\
						.\clibsdio.h	\
						.\clibstr.h		\
						.\clibstuf.h	\
						.\stdio.h	\
						.\string.h	\

NW_SRC				=	\
						.\CLIBstuf.c	\
						.\nw5.c		\
						.\nw5sck.c	\
						.\nw5thread.c \
						.\nwmain.c	\
						.\nwpipe.c  \
						.\nwplglob.c	\
						.\nwtinfo.c \
						.\nwutil.c  \

EXT_MAIN_SRC		=	\
						.\Main.c	\

PERL_IO_SRC			=	\
						..\perlio.c	

PERL_LIB_SRC		=	\
						.\interface.c	\
						.\nwperlsys.c \


NW_SRC_OBJ			= $(NW_SRC:.c=.obj)
NLM_MICROCORE_OBJ	= $(MICROCORE_SRC:.c=.obj) 
PERL_LIB_OBJ		= $(PERL_LIB_SRC:.c=.obj)
PERL_IO_OBJ			= $(PERL_IO_SRC:.c=.obj)
NLM_CORE_OBJ	    = $(NLM_MICROCORE_OBJ)
EXT_MAIN_OBJ		= $(EXT_MAIN_SRC:.c=.obj)

# For dependency checking 
# $(BLDDIR) in place of Release or Debug is not working, should look into this - sgp
!if "$(BLDDIR)"=="Release"
NLM_OBJ				= $(NLM_CORE_OBJ:..\=.\Release\)
NEWTARE_OBJ_DEP		= $(NW_SRC_OBJ:.\=.\Release\)
PERL_LIB_OBJ_DEP	= $(PERL_LIB_OBJ:.\=.\Release\)
PERL_IO_OBJ_DEP		= $(PERL_IO_OBJ:..\=.\Release\)
!else
NLM_OBJ				= $(NLM_CORE_OBJ:..\=.\Debug\)
NEWTARE_OBJ_DEP		= $(NW_SRC_OBJ:.\=.\Debug\)
PERL_LIB_OBJ_DEP	= $(PERL_LIB_OBJ:.\=.\Debug\)
PERL_IO_OBJ_DEP		= $(PERL_IO_OBJ:..\=.\Debug\)
!endif

# Symbol base_import & version added for NETWARE
NW_CFG_VARS = \
		"INST_DRV=$(INST_DRV)"			\
		"INST_TOP=$(INST_TOP)"			\
		"INST_VER=$(INST_VER)"			\
		"INST_ARCH=$(INST_ARCH)"		\
		"INST_NW_TOP1=$(INST_NW_TOP1)"	\
		"INST_NW_TOP2=$(INST_NW_TOP2)"	\
		"INST_NW_VER=$(INST_NW_VER)"	\
		"archname=$(ARCHNAME)"			\
		"cc=$(C_COMPILER)"				\
		"ccflags=$(COMPLER_FLAGS)"	\
		"cf_email=$(EMAIL)"			\
		"d_crypt=$(D_CRYPT)"			\
		"d_mymalloc=$(PERL_MALLOC)"		\
#		"libs=$(LIBFILES)"			\
		"incpath=$(NLM_INCLUDE_PATH)"	\
		"libperl=$(PERLIMPLIB:..\=)"		\
		"libpth=$(LIBPATH)"	\
#		"libc=$(LIBC)"				\
		"make=nmake"				\
		"static_ext=$(STATIC_EXT)"		\
		"dynamic_ext=$(DYNAMIC_EXT)"		\
		"nonxs_ext=$(NONXS_EXT)"		\
		"use5005threads=$(USE_5005THREADS)"	\
		"useithreads=$(USE_ITHREADS)"		\
		"usethreads=$(USE_5005THREADS)"		\
		"usemultiplicity=$(USE_MULTI)"		\
		"ld=$(NLM_LINK)"			\
		"base_import=$(BASE_IMPORT_FILES)"	\
		"LINK_FLAGS=$(LINK_FLAGS:"=\")"		\
		"optimize="		\
		"d_times=define"					\
		"d_stdio_cnt_lval=undef"		\
		"d_stdio_ptr_lval=undef"		\
		"d_stdiobase=undef"				\
		"d_stdstdio=undef"				\
		"d_times=undef"			\
		"direntrytype=DIR"				\
		"nlm_version=$(NLM_VERSION)"		\
		"d_archname=NetWare"	\
		"mpktool=$(MPKTOOL) $(XDCFLAGS)"	\
		"toolpath=$(TOOL_PATH)"


NW_CFGSH_TMPL	= config.wc
NW_CFGH_TMPL	= config_H.wc

SOCKET_NLP	= $(AUTODIR)\Socket\Socket.nlp
FCNTL_NLP	= $(AUTODIR)\Fcntl\Fcntl.nlp
IO_NLP		= $(AUTODIR)\IO\IO.nlp
OPCODE_NLP	= $(AUTODIR)\Opcode\Opcode.nlp
SDBM_FILE_NLP	= $(AUTODIR)\SDBM_File\SDBM_File.nlp
POSIX_NLP	= $(AUTODIR)\POSIX\POSIX.nlp
ATTRS_NLP	= $(AUTODIR)\attrs\attrs.nlp
THREAD_NLP	= $(AUTODIR)\Thread\Thread.nlp
B_NLP		= $(AUTODIR)\B\B.nlp
DUMPER_NLP	= $(AUTODIR)\Data\Dumper\Dumper.nlp
PEEK_NLP	= $(AUTODIR)\Devel\Peek\Peek.nlp
RE_NLP		= $(AUTODIR)\re\re.nlp
BYTELOADER_NLP	= $(AUTODIR)\ByteLoader\ByteLoader.nlp
DPROF_NLP	= $(AUTODIR)\Devel\DProf\DProf.nlp
GLOB_NLP	= $(AUTODIR)\File\Glob\Glob.nlp
CWD_NLP		= $(AUTODIR)\Cwd\Cwd.nlp
STORABLE_NLP	= $(AUTODIR)\Storable\Storable.nlp
LISTUTIL_NLP	= $(AUTODIR)\List\Util\Util.nlp
MIMEBASE64_NLP	= $(AUTODIR)\MIME\Base64\Base64.nlp
XSTYPEMAP_NLP	= $(AUTODIR)\XS\Typemap\Typemap.nlp

EXTENSION_NLP	= 		\
		$(FCNTL_NLP)	\
		$(BYTELOADER_NLP)	\
		$(IO_NLP)		\
		$(SOCKET_NLP)	\
		$(OPCODE_NLP)	\
		$(B_NLP)		\
		$(ATTRS_NLP)	\
		$(SDBM_FILE_NLP)	\
		$(POSIX_NLP)	\
		$(THREAD_NLP)	\
		$(DUMPER_NLP)	\
		$(GLOB_NLP)		\
		$(PEEK_NLP)		\
		$(RE_NLP)	\
		$(DPROF_NLP)	\
		$(STORABLE_NLP)	\
		$(LISTUTIL_NLP)	\
		$(MIMEBASE64_NLP) \
		$(XSTYPEMAP_NLP)	\
#		$(CWD_NLP)	\
# cwd.pm needs to be modifed for NetWare.

# Begin - Following is required to build NetWare specific extensions Perl2UCS & CGI2Perl

PERL2UCS		= $(EXTDIR)\Perl2UCS\Perl2UCS
CGI2PERL		= CGI2Perl\CGI2Perl

PERL2UCS_NLP = $(AUTODIR)\Perl2UCS\Perl2UCS.nlp
CGI2PERL_NLP = \CGI2Perl\CGI2Perl.nlp

NETWARE_EXTNS =	\
		$(PERL2UCS_NLP)	\
		$(CGI2PERL_NLP)

# End

ECHO_SRC			= TestNLM\echo\echo.c
TYPE_SRC			= TestNLM\type\type.c
ECHO_SRC_OBJ			= $(ECHO_SRC:.c=.obj)
TYPE_SRC_OBJ			= $(TYPE_SRC:.c=.obj)
ECHO_NLM	= TestNLM\echo\echo.nlm
TYPE_NLM	= TestNLM\type\type.nlm

TEST_NLMS	=	\
			$(ECHO_NLM)	\
			$(TYPE_NLM)	\

ERRNO_PM_NW	= $(LIBDIR)\Errno.pm

EXTENSION_NPM =	\
		$(ERRNO_PM_NW)	\


!ifndef SCREEN
SCREEN          = 'none'
!endif

!ifndef NLM_DESCRIPTION
NLM_DESCRIPTION = $(NLM_NAME8) for Netware
!endif

!ifndef NLM_VERSION
NLM_VERSION    = 5.72.0
!endif

!ifndef NLM_EXT
NLM_EXT        = NLM
!endif

!ifndef BUILT
BUILT     = $(BLDDIR)\$(NLM_NAME8).$(NLM_EXT)
!endif

!ifndef BASE_IMPORT_FILES
BASE_IMPORT_FILES = Import @$(NLMIMPORTS)\clib.imp, @$(NLMIMPORTS)\nlmlib.imp, @$(NLMIMPORTS)\threads.imp, @$(NLMIMPORTS)\nit.imp, @$(NLMIMPORTS)\socklib.imp, @$(NLMIMPORTS)\fpsm.imp, @$(NLMIMPORTS)\lib0.imp
!endif

!ifdef USE_MPK
BASE_IMPORT_FILES = $(BASE_IMPORT_FILES), @$(MPKBASE)\import\mpkorg.imp
!endif

!ifndef BASE_IMPORT_FNS
BASE_IMPORT_FNS = Import ImportSymbol, GetSystemConsoleScreen, LoadModule
!endif

!ifdef WATCOM
NWLIBPATH  = $(WATCOM)\lib386\netware
LIBPATH386 = $(WATCOM)\lib386
LIBPATH = $(NWLIBPATH);$(LIBPATH386)
!else																#!ifdef WATCOM
!ifdef CODEWARRIOR
NWLIBPATH  = 
LIBPATH386 =
LIBPATH = 
!else																#!ifdef CODEWARRIOR
!error Please define the tools base directory before proceeding
!endif																#!ifdef CODEWARRIOR
!endif																#!ifdef WATCOM

!ifndef BASE_LIBRARIES
!ifdef WATCOM
BASE_LIBRARIES = Library plib3s.lib,math3s.lib,clib3s.lib
!else
!ifdef CODEWARRIOR
BASE_LIBRARIES = 
!endif																#!ifdef CODEWARRIOR
!endif																#!ifdef WATCOM	
!endif																#!ifndef BASE_LIBRARIES

COPYRIGHT = Copyright 2001 by Novell, Inc. All rights reserved.

EXPORTS = Export @perl.imp

#
# Set these to wherever you want "nmake install" to put your
# newly built perl.
#
INST_DRV	= c:
INST_TOP	= $(INST_DRV)\perl

INST_NW_DRV = i:
INST_NW_VOL = sys:
INST_NW_TOP1 = $(INST_NW_VOL)\perl
INST_NW_TOP2 = $(INST_NW_DRV)\perl
#INST_NW_VER = \5.6.1

#
# Comment this out if you DON'T want your perl installation to be versioned.
# This means that the new installation will overwrite any files from the
# old installation at the same INST_TOP location.  Leaving it enabled is
# the safest route, as perl adds the extra version directory to all the
# locations it installs files to.  If you disable it, an alternative
# versioned installation can be obtained by setting INST_TOP above to a
# path that includes an arbitrary version string.
#
INST_VER	= \5.7.2

#
# Comment this out if you DON'T want your perl installation to have
# architecture specific components.  This means that architecture-
# specific files will be installed along with the architecture-neutral
# files.  Leaving it enabled is safer and more flexible, in case you
# want to build multiple flavors of perl and install them together in
# the same location.  Commenting it out gives you a simpler
# installation that is easier to understand for beginners.
#
INST_ARCH	= \$(ARCHNAME)

#
# uncomment to enable multiple interpreters.  This is need for fork()
# emulation.
#
USE_MULTI	= define

#
# Beginnings of interpreter cloning/threads; still very incomplete.
# This should be enabled to get the fork() emulation.  This needs
# USE_MULTI as well.
#
USE_ITHREADS	= define

#
# uncomment to enable the implicit "host" layer for all system calls
# made by perl.  This needs USE_MULTI above.  This is also needed to
# get fork().
#
USE_IMP_SYS	= define

# uncomment this to enable the experimental PerlIO I/O subsystem
# else USE_STDIO will be defined.
#USE_PERLIO	= define
#USE_STDIO = define

#
# WARNING! This option is deprecated and will eventually go away (enable
# USE_ITHREADS instead).
#
# uncomment to enable threads-capabilities.  This is incompatible with
# USE_ITHREADS, and is only here for people who may have come to rely
# on the experimental Thread support that was in 5.005.
#
#USE_5005THREADS= define

#
# WARNING! This option is deprecated and will eventually go away (enable
# USE_MULTI instead).
#
# uncomment next line if you want to use the PERL_OBJECT build option.
# DO NOT ENABLE unless you have legacy code that relies on the C++
# CPerlObj class that was available in 5.005.  This cannot be enabled
# if you ask for USE_5005THREADS above.
#
#USE_OBJECT	= define

# For now let this be here
#
#CRYPT_SRC	= fcrypt.c

# For now let this be here
#
#CRYPT_LIB	= fcrypt.lib

#
# set this if you wish to use perl's malloc
# WARNING: Turning this on/off WILL break binary compatibility with extensions
# you may have compiled with/without it.  Be prepared to recompile all
# extensions if you change the default.  Currently, this cannot be enabled
# if you ask for USE_IMP_SYS above.
#
#PERL_MALLOC	= define

#
# set this to your email address (perl will guess a value from
# from your loginname and your hostname, which may not be right)
#
#EMAIL		=

##
## Build configuration ends.
##

##################### CHANGE THESE ONLY IF YOU MUST #####################

!IF "$(CRYPT_SRC)$(CRYPT_LIB)" == ""
D_CRYPT		= undef
!ELSE
D_CRYPT		= define
CRYPT_FLAG	= -DHAVE_DES_FCRYPT
!ENDIF

!IF "$(USE_OBJECT)" == "define"
PERL_MALLOC	= undef
USE_5005THREADS	= undef
USE_MULTI	= undef
USE_IMP_SYS	= define
!ENDIF

!IF "$(PERL_MALLOC)" == ""
PERL_MALLOC	= undef
!ENDIF

!IF "$(USE_5005THREADS)" == ""
USE_5005THREADS	= undef
!ENDIF

!IF "$(USE_5005THREADS)" == "define"
USE_ITHREADS	= undef
!ENDIF

!IF "$(USE_IMP_SYS)" == "define"
PERL_MALLOC	= undef
!ENDIF

!IF "$(USE_MULTI)" == ""
USE_MULTI	= undef
!ENDIF

!IF "$(USE_OBJECT)" == ""
USE_OBJECT	= undef
!ENDIF

!IF "$(USE_ITHREADS)" == ""
USE_ITHREADS	= undef
!ENDIF

!IF "$(USE_IMP_SYS)" == ""
USE_IMP_SYS	= undef
!ENDIF

!IF "$(USE_PERLCRT)" == ""
USE_PERLCRT	= undef
!ENDIF

!IF "$(USE_IMP_SYS)$(USE_MULTI)$(USE_5005THREADS)$(USE_OBJECT)" == "defineundefundefundef"
USE_MULTI	= define
!ENDIF

!IF "$(USE_ITHREADS)$(USE_MULTI)$(USE_OBJECT)" == "defineundefundef"
USE_MULTI	= define
USE_5005THREADS	= undef
!ENDIF

!IF "$(USE_MULTI)$(USE_5005THREADS)$(USE_OBJECT)" != "undefundefundef"
BUILDOPT	= $(BUILDOPT) -DPERL_IMPLICIT_CONTEXT
!ENDIF

!IF "$(USE_IMP_SYS)" != "undef"
BUILDOPT	= $(BUILDOPT) -DPERL_IMPLICIT_SYS
!ENDIF

!IF "$(PROCESSOR_ARCHITECTURE)" == ""
PROCESSOR_ARCHITECTURE	= x86
!ENDIF

!IF "$(USE_OBJECT)" == "define"
ARCHNAME	= NetWare-$(PROCESSOR_ARCHITECTURE)-object
!ELSE
!IF "$(USE_5005THREADS)" == "define"
ARCHNAME	= NetWare-$(PROCESSOR_ARCHITECTURE)-thread
!ELSE
!IF "$(USE_MULTI)" == "define"
ARCHNAME	= NetWare-$(PROCESSOR_ARCHITECTURE)-multi
!ELSE
ARCHNAME	= NetWare-$(PROCESSOR_ARCHITECTURE)
!ENDIF
!ENDIF
!ENDIF

!IF "$(USE_MULTI)$(USE_5005THREADS)$(USE_OBJECT)" != "undefundefundef"
ADD_BUILDOPT	= $(ADD_BUILDOPT) -DPERL_IMPLICIT_CONTEXT
!ENDIF

!IF "$(USE_IMP_SYS)" != "undef"
ADD_BUILDOPT	= $(ADD_BUILDOPT) -DPERL_IMPLICIT_SYS
!ENDIF

!IF "$(USE_ITHREADS)" == "define"
ARCHNAME	= $(ARCHNAME)-thread
!ENDIF

!IF "$(USE_PERLIO)" == "define"
USE_STDIO		= undef
ADD_BUILDOPT	= $(ADD_BUILDOPT) -DUSE_PERLIO
ARCHNAME		= $(ARCHNAME)-perlio
!ELSE
#USE_STDIO	= define
#ADD_BUILDOPT	= $(ADD_BUILDOPT) -DUSE_STDIO
!ENDIF

ARCHDIR		= ..\lib\$(ARCHNAME)
COREDIR		= ..\lib\CORE
AUTODIR		= ..\lib\auto
LIBDIR		= ..\lib
EXTDIR		= ..\ext
PODDIR		= ..\pod
EXTUTILSDIR	= $(LIBDIR)\ExtUtils

#
INST_SCRIPT	= $(INST_TOP)$(INST_VER)\bin
INST_BIN	= $(INST_SCRIPT)$(INST_ARCH)
INST_LIB	= $(INST_TOP)$(INST_VER)\lib
INST_ARCHLIB	= $(INST_LIB)$(INST_ARCH)
INST_COREDIR	= $(INST_ARCHLIB)\CORE
INST_POD	= $(INST_LIB)\pod
INST_HTML	= $(INST_POD)\html

#
# Options
#

!IF "$(USE_OBJECT)" == "define"
OPTIMIZE	= $(OPTIMIZE) $(CXX_FLAG)
BUILDOPT	= $(BUILDOPT) -DPERL_OBJECT
!ENDIF

OBJOUT_FLAG	= -Fo
EXEOUT_FLAG	= -Fe


#################### do not edit below this line #######################
############# NO USER-SERVICEABLE PARTS BEYOND THIS POINT ##############

o = .obj

#
# Rules
# 

.SUFFIXES : .c $(o) .nlm .lib .nlp


#
# various targets
PERLIMPLIB	= ..\perl.lib

MINIPERL	= ..\miniperl.exe
CONFIGPM	= ..\lib\Config.pm
MINIMOD		= ..\lib\ExtUtils\Miniperl.pm
X2P			= ..\x2p\a2p.nlm

PL2BAT		= ..\win32\bin\pl2bat.pl

UTILS		=			\
		..\utils\h2ph		\
		..\utils\splain		\
		..\utils\dprofpp	\
		..\utils\perlbug	\
		..\utils\pl2pm 		\
		..\utils\c2ph		\
		..\utils\h2xs		\
		..\utils\perldoc	\
		..\utils\perlcc		\
		..\pod\checkpods	\
		..\pod\pod2html		\
		..\pod\pod2latex	\
		..\pod\pod2man		\
		..\pod\pod2text		\
		..\pod\pod2usage	\
		..\pod\podchecker	\
		..\pod\podselect	\
		..\x2p\find2perl	\
		..\x2p\s2p		

MAKE		= nmake -nologo

XCOPY		= xcopy /f /r /i /d
RCOPY		= xcopy /f /r /i /e /d
NOOP		= @echo
NULL		=

#
# filenames given to xsubpp must have forward slashes (since it puts
# full pathnames in #line strings)
XSUBPP		= ..\$(MINIPERL) -I..\..\lib ..\$(EXTUTILSDIR)\xsubpp \
		-C++ -prototypes

MICROCORE_SRC	=		\
		..\av.c		\
		..\deb.c	\
		..\doio.c	\
		..\doop.c	\
		..\dump.c	\
		..\globals.c	\
		..\gv.c		\
		..\hv.c		\
		..\locale.c	\
		..\mg.c		\
		..\numeric.c	\
		..\op.c		\
		..\perl.c	\
		..\perlapi.c	\
		..\perly.c	\
		..\pp.c		\
		..\pp_ctl.c	\
		..\pp_hot.c	\
		..\pp_pack.c	\
		..\pp_sys.c	\
		..\regcomp.c	\
		..\regexec.c	\
		..\run.c	\
		..\scope.c	\
		..\sv.c		\
		..\taint.c	\
		..\toke.c	\
		..\universal.c	\
		..\utf8.c	\
		..\util.c	\
		..\xsutils.c

#EXTRACORE_SRC	= $(EXTRACORE_SRC) perllib.c

!IF "$(PERL_MALLOC)" == "define"
EXTRACORE_SRC	= $(EXTRACORE_SRC) ..\malloc.c
!ENDIF

#!IF "$(USE_OBJECT)" != "define"
#EXTRACORE_SRC	= $(EXTRACORE_SRC) ..\perlio.c
#!ENDIF

!IF "$(CRYPT_SRC)" != ""
NW_SRC	= $(NW_SRC) .\$(CRYPT_SRC)
!ENDIF

DLL_SRC		= $(DYNALOADER).c

X2P_SRC		=		\
		..\x2p\a2p.c	\
		..\x2p\hash.c	\
		..\x2p\str.c	\
		..\x2p\util.c	\
		..\x2p\walk.c

CORE_NOCFG_H	=		\
		..\av.h		\
		..\cop.h	\
		..\cv.h		\
		..\dosish.h	\
		..\embed.h	\
		..\form.h	\
		..\gv.h		\
		..\handy.h	\
		..\hv.h		\
		..\iperlsys.h	\
		..\mg.h		\
		..\nostdio.h	\
		..\op.h		\
		..\opcode.h	\
		..\perl.h	\
		..\perlapi.h	\
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
		..\utf8.h	\
		..\util.h	\
		..\warnings.h	\
		..\XSUB.h	\
		..\EXTERN.h	\
		..\perlvars.h	\
		..\intrpvar.h	\
		..\thrdvar.h	\
		
CORE_H		= $(CORE_NOCFG_H) .\config.h

DLL_OBJ		= $(DLL_SRC:.c=.obj)
X2P_OBJ		= $(X2P_SRC:.c=.obj)

DYNAMIC_EXT	= Socket IO Fcntl Opcode SDBM_File POSIX attrs Thread B re \
		Data/Dumper Devel/Peek ByteLoader Devel/DProf File/Glob \
		Storable/Storable List/Util MIME/Base64/Base64 XS/Typemap/Typemap

STATIC_EXT	= DynaLoader
NONXS_EXT	= Errno

DYNALOADER	= $(EXTDIR)\DynaLoader\DynaLoader
SOCKET		= $(EXTDIR)\Socket\Socket
FCNTL		= $(EXTDIR)\Fcntl\Fcntl
OPCODE		= $(EXTDIR)\Opcode\Opcode
SDBM_FILE	= $(EXTDIR)\SDBM_File\SDBM_File
IO			= $(EXTDIR)\IO\IO
POSIX		= $(EXTDIR)\POSIX\POSIX
ATTRS		= $(EXTDIR)\attrs\attrs
THREAD		= $(EXTDIR)\Thread\Thread
B			= $(EXTDIR)\B\B
RE			= $(EXTDIR)\re\re
DUMPER		= $(EXTDIR)\Data\Dumper\Dumper
ERRNO		= $(EXTDIR)\Errno\Errno
PEEK		= $(EXTDIR)\Devel\Peek\Peek
BYTELOADER	= $(EXTDIR)\ByteLoader\ByteLoader
DPROF		= $(EXTDIR)\Devel\DProf\DProf
GLOB		= $(EXTDIR)\File\Glob\Glob
CWD			= $(EXTDIR)\Cwd\Cwd
STORABLE	= $(EXTDIR)\Storable\Storable
LISTUTIL	= $(EXTDIR)\List\Util
MIMEBASE64	= $(EXTDIR)\MIME\Base64\Base64
XSTYPEMAP	= $(EXTDIR)\XS\Typemap\Typemap

EXTENSION_C	= 		\
		$(SOCKET).c	\
		$(FCNTL).c	\
		$(OPCODE).c	\
		$(SDBM_FILE).c	\
		$(IO).c		\
		$(POSIX).c	\
		$(ATTRS).c	\
		$(THREAD).c	\
		$(RE).c		\
		$(DUMPER).c	\
		$(PEEK).c	\
		$(B).c		\
		$(BYTELOADER).c	\
		$(DPROF).c	\
		$(GLOB).c	\
		$(CWD).c	\
		$(STORABLE).c	\
		$(LISTUTIL).c	\
		$(MIMEBASE64).c	\
		$(XSTYPEMAP).c	\

POD2HTML	= $(PODDIR)\pod2html
POD2MAN		= $(PODDIR)\pod2man
POD2LATEX	= $(PODDIR)\pod2latex
POD2TEXT	= $(PODDIR)\pod2text

#
# Top targets
#

all : .cleanoldfiles .\nwconfig.h $(CONFIGPM) $(NLM_NAME) $(EXTENSION_NLP) $(EXTENSION_NPM) $(TEST_NLMS) $(NETWARE_EXTNS)

#------------------------------------------------------------

..\config.sh : config.nw5 $(MINIPERL) config_sh.PL
	$(MINIPERL) -I..\lib config_sh.PL $(NW_CFG_VARS) config.nw5 > ..\config.sh

# this target is for when changes to the main config.sh happen
# edit config.{b,v,g,w}c and make this target once for each supported
# compiler (e.g. `dmake CCTYPE=BORLAND regen_config_h`)
regen_config_h:
	perl config_sh.PL $(NW_CFG_VARS) $(NW_CFGSH_TMPL) > ..\config.sh
	cd ..
	-del /f perl.exe
	perl configpm
	cd netware
	-del /f $(NW_CFGH_TMPL)
	-mkdir $(COREDIR)
	-perl -I..\lib config_h.PL "INST_VER=$(INST_VER)"
	rename config.h $(NW_CFGH_TMPL)

$(CONFIGPM) : $(MINIPERL) ..\config.sh config_h.PL ..\minimod.pl
	cd .. && miniperl configpm
	if exist lib\* $(RCOPY) lib\*.* ..\lib\$(NULL)
	$(XCOPY) ..\*.h $(COREDIR)\*.*
	$(XCOPY) *.h $(COREDIR)\*.*
	$(XCOPY) ..\ext\re\re.pm $(LIBDIR)\*.*
	if exist include\* $(RCOPY) include $(COREDIR)\*.*
	$(MINIPERL) -I..\lib config_h.PL "INST_VER=$(INST_VER)" \
	    || $(MAKE) /$(MAKEFLAGS) $(CONFIGPM)

$(MINIPERL) : 
	$(error)Please build $(MINIPERL) before continuing

$(MINIMOD) : $(MINIPERL) ..\minimod.pl
	cd .. && miniperl minimod.pl > lib\ExtUtils\Miniperl.pm

..\x2p\a2p$(o) : ..\x2p\a2p.c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(C_COMPILER) -I..\x2p $(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\x2p\a2p.c

..\x2p\hash$(o) : ..\x2p\hash.c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(C_COMPILER) -I..\x2p  $(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS)  $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\x2p\hash.c

..\x2p\str$(o) : ..\x2p\str.c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(C_COMPILER) -I..\x2p  $(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\x2p\str.c

..\x2p\util$(o) : ..\x2p\util.c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(C_COMPILER) -I..\x2p  $(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\x2p\util.c

..\x2p\walk$(o) : ..\x2p\walk.c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(C_COMPILER) -I..\x2p  $(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\x2p\walk.c

$(X2P) : $(MINIPERL) $(X2P_OBJ)
	$(MINIPERL) ..\x2p\find2perl.PL
	$(MINIPERL) ..\x2p\s2p.PL
!ifdef USE_XDC
	$(MPKTOOL) $(XDCFLAGS) $*.xdc
!endif
!ifdef WATCOM
	@$(NLM_LINK) @<<$*.link
 Form   Novell NLM 'Awk to Perl converter'
 Name   $(X2P)
  Option Quiet
 Option Version = $(NLM_VERSION)
 Option Copyright '$(COPYRIGHT)'
 Option Caseexact
 Option Map=$*.map, Verbose, screenname 'System Console'
 Option Stack=32k
 Option SYMFILE=$*.sym
!ifdef USE_XDC
 OPTION	XDCDATA=$*.xdc
!endif
 Option NoDefaultLibs
 $(EXTRA_LINK_OPTION)
!if "$(MAKE_TYPE)"=="Debug"
   Debug novell
   Debug codeview
!endif
LibPath $(LIBPATH)
 $(BASE_LIBRARIES)
 Module clib
 $(BASE_IMPORT_FNS)
 $(BASE_IMPORT_FILES)
 $(ADD_IMPORT_FNS)
Import @perl.imp
 $(EXPORTS)
 File   $(X2P_OBJ:.obj=,) .\$(BLDDIR)\clibstuf.obj
<<KEEP
!else
!ifdef CODEWARRIOR	
# Linker definitions and lining come here for CODEWARRIOR
!endif
!endif

$(EXTDIR)\DynaLoader\dl_netware.xs: dl_netware.xs
	copy dl_netware.xs $(EXTDIR)\DynaLoader\dl_netware.xs

HEADERS :
	@echo . . . . making stdio.h and string.h
	@copy << stdio.h >\nul

/*
 * Copyright © 2001 Novell, Inc. All Rights Reserved.
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the README file.
 *
 */

/*
 * FILENAME		:	stdio.h
 * DESCRIPTION	:	Generated header file, do not edit. See makefile.
 *                  This header file causes the includer to use clibstuf.h
 *                  The purpose of clibstuf is to make sure that Perl, cgi2perl and
 *                  all the perl extension nlm's (*.NLP) use the Novell Netware CLIB versions
 *                  of standard functions. This code loads up a whole bunch of function pointers
 *                  to point at the standard CLIB functions.
 * Author		:	HYAK
 * Date			:	January 2001.
 *
 */


#ifndef __Stdio_H__
#define __Stdio_H__


#include "$(NLMSDKBASE)\INCLUDE\NLM\stdio.h"
#include "clibsdio.h"


#endif	// __Stdio_H__

<<
	@copy stdio.h $(COREDIR)
	 
	@copy << string.h >\nul

/*
 * Copyright © 2001 Novell, Inc. All Rights Reserved.
 *
 * You may distribute under the terms of either the GNU General Public
 * License or the Artistic License, as specified in the README file.
 *
 */

/*
 * FILENAME		:	string.h
 * DESCRIPTION	:	Generated header file, do not edit. See makefile.
 *                  This header file causes the includer to use clibstuf.h
 *                  The purpose of clibstuf is to make sure that Perl, cgi2perl and
 *                  all the perl extension nlm's (*.NLP) use the Novell Netware CLIB versions
 *                  of standard functions. This code loads up a whole bunch of function pointers
 *                  to point at the standard CLIB functions.
 * Author		:	HYAK
 * Date			:	January 2001.
 *
 */


#ifndef __String_H__
#define __String_H__


#include "$(NLMSDKBASE)\INCLUDE\NLM\string.h"
#include "clibstr.h"


#endif	// __String_H__

<<
	@copy string.h $(COREDIR)


$(NLM_NAME): MESSAGE HEADERS $(BLDDIR)\nul $(NLM_OBJ) $(NEWTARE_OBJ_DEP) $(PERL_IO_OBJ_DEP) $(PERL_LIB_OBJ_DEP) $(DLL_OBJ) .XDC $(PERLIMPLIB) $(EXT_MAIN_OBJ)
	@echo======= Linking $@ at $(MAKEDIR)\$(BLDDIR) =======
!ifdef WATCOM
	@$(NLM_LINK) @<<$(BLDDIR)\$*.link
 Form   Novell NLM '$(NLM_DESCRIPTION)'
 Name   $(BUILT)
 Option Quiet
 Option Version = $(NLM_VERSION)
 Option Copyright '$(COPYRIGHT)'
 Option Caseexact
 Option Map=$(BLDDIR)\$(NLM_NAME8).map, Verbose, screenname $(SCREEN)
 Option Stack=1000
!ifdef NLM_NAME8
 Option SYMFILE=$(BLDDIR)\$(NLM_NAME8).sym
!ifdef USE_XDC
 OPTION	XDCDATA=$(BLDDIR)\$(NLM_NAME8).xdc
!endif
!else
 Option SYMFILE=$(BLDDIR)\$(NLM_NAME).sym
!ifdef USE_XDC
 OPTION	XDCDATA=$(BLDDIR)\$(NLM_NAME).xdc
!endif
!endif
 Option NoDefaultLibs
 $(EXTRA_LINK_OPTION)
!if "$(MAKE_TYPE)"=="Debug"
   # Debug all
   Debug novell
   Debug codeview
!endif
LibPath $(LIBPATH)
 $(BASE_LIBRARIES)
 Module clib
 $(BASE_IMPORT_FNS)
 $(BASE_IMPORT_FILES)
 $(ADD_IMPORT_FNS)
Import @perl.imp
 $(EXPORTS)
 File   $(NEWTARE_OBJ_DEP:.obj=.obj,) $(NLM_OBJ:.obj=.obj,) $(PERL_IO_OBJ_DEP:.obj=.obj,) $(PERL_LIB_OBJ_DEP:.obj=.obj,) $(DLL_OBJ:.obj=.obj,)
<<KEEP
!else
!ifdef CODEWARRIOR	
# Linker definitions and lining come here for CODEWARRIOR
!endif
!endif
	copy ..\win32\splittree.pl .. 
	$(MINIPERL) -I..\lib ..\splittree.pl "../LIB" $(AUTODIR)


!if "$(MAKE_TYPE)"=="Debug"
!ifdef NLM_NAME8
 	.\bat\cvpack $(BLDDIR)\$(NLM_NAME8).sym
!else
 	.\bat\cvpack $(BLDDIR)\$(NLM_NAME).sym
!endif
!endif

	@echo======= Finished building $(BUILT).
 
# Create the debug\release directory if not existing
$(BLDDIR)\nul:
	@echo . . . . mkdir $(BLDDIR)
	@mkdir $(BLDDIR)

MESSAGE: 
	@echo======= $(MAKE_ACTION)ing $(NLM_NAME) at $(MAKEDIR)\$(BLDDIR) ======= 

.XDC:
!ifdef USE_XDC
        @echo======= Creating XDC file
!ifdef NLM_NAME8
        $(MPKTOOL) $(XDCFLAGS) $(BLDDIR)\$(NLM_NAME8).xdc
!else
        $(MPKTOOL) $(XDCFLAGS) $(BLDDIR)\$(NLM_NAME).xdc
!endif
!endif

$(PERLIMPLIB): perllib.def
	$(NLM_LIB) -def:perllib.def -out:$(PERLIMPLIB)
	$(XCOPY) $(PERLIMPLIB) $(COREDIR)

perllib.def : $(MINIPERL) $(CONFIGPM) ..\global.sym ..\pp.sym ..\makedef.pl
	$(MINIPERL) -w ..\makedef.pl PLATFORM=netware FILETYPE=def $(BS_CFLAGS) $(DEFINES) $(ADD_BUILDOPT) \
	    CCTYPE=$(CCTYPE) > perllib.def
	$(MINIPERL) -w ..\makedef.pl PLATFORM=netware FILETYPE=imp $(BS_CFLAGS) $(DEFINES) $(ADD_BUILDOPT) \
	    CCTYPE=$(CCTYPE) > perl.imp

$(DLL_OBJ) : $(DYNALOADER).c $(CORE_H) $(EXTDIR)\DynaLoader\dlutils.c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(C_COMPILER) @<<$(BLDDIR)\$(*F).options 
	$(NLM_INCLUDES) -I$(EXTDIR)\DynaLoader\ $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$(BLDDIR)\$(*F).err $(EXTDIR)\DynaLoader\$(*F).c
<<KEEP

$(DYNALOADER).c : $(MINIPERL) $(EXTDIR)\DynaLoader\dl_netware.xs $(CONFIGPM)
	if not exist $(AUTODIR) mkdir $(AUTODIR)
	cd $(EXTDIR)\$(*B)
	..\$(MINIPERL) -I..\..\lib $(*B)_pm.PL
	..\$(MINIPERL) -I..\..\lib XSLoader_pm.PL
	cd ..\..\netware
	$(XCOPY) $(EXTDIR)\$(*B)\$(*B).pm $(LIBDIR)\$(NULL)
	$(XCOPY) $(EXTDIR)\$(*B)\XSLoader.pm $(LIBDIR)\$(NULL)
	cd $(EXTDIR)\$(*B)
	$(XSUBPP) dl_netware.xs > $(*B).c
	cd ..\..\netware

$(PERL_LIB_OBJ_DEP) : $(NW_HOST_H_FILES) $(*F).c
	@echo $(MPKMESSAGE)...$(BLDMESG)...$@
	@$(CPP_COMPILER) @<<$(BLDDIR)\$(*F).options 
	-I.. $(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err $(*F).c
<<KEEP

$(PERL_IO_OBJ_DEP) : ..\$(*F).c
	@echo $(MPKMESSAGE) $(BLDMESG) $@
	@$(C_COMPILER) @<<$(BLDDIR)\$(*F).options 
	$(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\$(*F).c
<<KEEP

$(NLM_OBJ)	: ..\$(*F).c
	@echo $(MPKMESSAGE) $(BLDMESG) $@
	@$(C_COMPILER) @<<$(BLDDIR)\$(*F).options 
	$(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err ..\$(*F).c
<<KEEP

$(NEWTARE_OBJ_DEP) : $(NW_H_FILES) $(NW_HOST_H_FILES) $(*F).c
	@echo $(MPKMESSAGE) $(BLDMESG) $@
	@$(C_COMPILER) @<<$(BLDDIR)\$(*F).options 
	$(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err $(*F).c
<<KEEP

$(EXT_MAIN_OBJ) : $(CLIB_H_FILES)
	@echo $(MPKMESSAGE) $(BLDMESG) $@
	@$(C_COMPILER) @<<$(BLDDIR)\$(*F).options
	$(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err $(*F).c
<<KEEP
	$(NLM_LIB) $@ $(NLMIMPORTS)\prelude.obj -out:$*.lib
	@copy $*.lib $(COREDIR)

# Delete any files that might have got created during building miniperl.exe
# config.sh will definitely be created
# COREDIR might have got created
.cleanoldfiles :
	-del ..\config.sh
	-del .\Main.obj
	-del .\Main.lib
	-rmdir /s /q $(AUTODIR)
	-rmdir /s /q $(COREDIR)

.\nwconfig.h : $(NW_CFGH_TMPL)
	-del /f config.h
	copy $(NW_CFGH_TMPL) config.h

# REQUIRED WHEN WE INCLUDE CONFIGPM OR REGEN_CONFIG - sgp
#..\nwconfig.sh : config.nw5 $(MINIPERL) config_sh.PL
#	$(MINIPERL) -I..\lib config_sh.PL $(NW_CFG_VARS) config.nw5 > ..\config.sh
#	@pause
#	cd ..
#	del config.sh
#	rename nwconfig.sh config.sh
#	cd netware

config.nw5 : $(NW_CFGSH_TMPL)
	copy $(NW_CFGSH_TMPL) config.nw5

$(SOCKET_NLP): $(NLM_NAME) $(SOCKET).xs
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(FCNTL_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(IO_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(OPCODE_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(B_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(DUMPER_NLP):
	cd $(EXTDIR)\Data\$(*B)
	..\..\..\miniperl -I..\..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(PEEK_NLP):
	cd $(EXTDIR)\Devel\$(*B)
	..\..\..\miniperl -I..\..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(RE_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(BYTELOADER_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(DPROF_NLP):
	cd $(EXTDIR)\Devel\$(*B)
	..\..\..\miniperl -I..\..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(GLOB_NLP):
	cd $(EXTDIR)\File\$(*B)
	..\..\..\miniperl -I..\..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(POSIX_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(THREAD_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(ATTRS_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(SDBM_FILE_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(CWD_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(STORABLE_NLP):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(LISTUTIL_NLP):
	cd $(EXTDIR)\List\$(*B)
	..\..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(MIMEBASE64_NLP):
	cd $(EXTDIR)\Mime\$(*B)
	..\..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(XSTYPEMAP_NLP):
	cd $(EXTDIR)\XS\$(*B)
	..\..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\..\netware

$(ERRNO_PM_NW):
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware

$(ECHO_SRC_OBJ): $*.c
	@echo $(MPKMESSAGE) $(BLDMESG) $@
	@$(C_COMPILER) @<<$*.options 
	$(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err $*.c
<<KEEP

$(ECHO_NLM): $(ECHO_SRC_OBJ)
	@echo======= Linking $@ =======
!ifdef USE_XDC
	$(MPKTOOL) $(XDCFLAGS) $*.xdc
!endif
!ifdef WATCOM
	@$(NLM_LINK) @<<$*.link
 Form   Novell NLM 'DOS echo emulation for Perl Testing' Name $@ 
 Option Quiet Option Version = $(NLM_VERSION) Option Copyright '$(COPYRIGHT)' Option Caseexact Option Map=$*.map, Verbose, screenname 'System Console' Option Stack=1000 Option SYMFILE=$*.sym  Option NoDefaultLibs
!ifdef USE_XDC
 OPTION	XDCDATA=$*.xdc
!endif
 $(EXTRA_LINK_OPTION)
!if "$(MAKE_TYPE)"=="Debug"
   Debug novell
   Debug codeview
!endif
LibPath $(LIBPATH)
 $(BASE_LIBRARIES) Module clib $(BASE_IMPORT_FNS) $(BASE_IMPORT_FILES) $(ADD_IMPORT_FNS)
Import @perl.imp
 $(EXPORTS)
 File   $(ECHO_SRC_OBJ:.obj=.obj,) .\$(BLDDIR)\clibstuf.obj
<<KEEP
!else
!ifdef CODEWARRIOR	
# Linker definitions and lining come here for CODEWARRIOR
!endif
!endif
	@echo======= Linking Complete =======

$(TYPE_SRC_OBJ): $*.c
	@echo $(MPKMESSAGE) $(BLDMESG) $@
	@$(C_COMPILER) @<<$*.options 
	$(NLM_INCLUDES) $(COMPLER_FLAGS) $(ADD_LOCDEFS) $(OBJOUT_FLAG)$@ $(ERROR_FLAG)$*.err $*.c
<<KEEP

$(TYPE_NLM): $(TYPE_SRC_OBJ)
	@echo======= Linking $@ =======
!ifdef USE_XDC
	$(MPKTOOL) $(XDCFLAGS) $*.xdc
!endif
!ifdef WATCOM
	@$(NLM_LINK) @<<$*.link
 Form   Novell NLM 'DOS type emulation for Perl Testing' Name $@ 
 Option Quiet Option Version = $(NLM_VERSION) Option Copyright '$(COPYRIGHT)' Option Caseexact Option Map=$*.map, Verbose, screenname 'System Console' Option Stack=1000 Option SYMFILE=$*.sym
!ifdef USE_XDC
 OPTION	XDCDATA=$*.xdc
!endif
 Option NoDefaultLibs
 $(EXTRA_LINK_OPTION)
!if "$(MAKE_TYPE)"=="Debug"
   Debug novell
   Debug codeview
!endif
LibPath $(LIBPATH)
 $(BASE_LIBRARIES) Module clib $(BASE_IMPORT_FNS) $(BASE_IMPORT_FILES) $(ADD_IMPORT_FNS)
Import @perl.imp
 $(EXPORTS)
 File   $(TYPE_SRC_OBJ:.obj=.obj,) .\$(BLDDIR)\clibstuf.obj
<<KEEP
!else
!ifdef CODEWARRIOR	
# Linker definitions and lining come here for CODEWARRIOR
!endif
!endif
	@echo======= Linking Complete =======

# Build NetWare specific extensions
$(CGI2PERL_NLP):
!if "$(NW_EXTNS)"=="yes"
	cd $(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware
!endif

$(PERL2UCS_NLP):
!if "$(NW_EXTNS)"=="yes"
	cd $(EXTDIR)\$(*B)
	..\..\miniperl -I..\..\lib Makefile.PL INSTALLDIRS=perl
	$(MAKE)
	cd ..\..\netware
!endif

nwclean:
	-rmdir /s /q $(REL_DIR) || rmdir /s $(REL_DIR)
	-rmdir /s /q $(DEB_DIR) || rmdir /s $(DEB_DIR)
	@if exist .\stdio.h del .\stdio.h
	@if exist .\string.h del .\string.h
	@if exist .\Main.obj del .\Main.obj
	@if exist .\Main.lib del .\Main.lib
	cd testnlm\echo
	-del *.obj *.map *.link *.options *.nlm *.sym *.xdc *.err
	cd ..\type
	-del *.obj *.map *.link *.options *.nlm *.sym *.xdc *.err
	cd ..\..\

utils: $(BLDDIR)\$(NLM_NAME8).$(NLM_EXT) $(X2P)
	cd ..\utils
	$(MAKE) PERL=$(MINIPERL)
	cd ..\pod
	copy ..\README.amiga .\perlamiga.pod
	copy ..\README.cygwin .\perlcygwin.pod
	copy ..\README.dos .\perldos.pod
	copy ..\README.hpux .\perlhpux.pod
#	copy ..\README.machten .\perlmachten.pod
	copy ..\README.os2 .\perlos2.pod
	copy ..\vms\perlvms.pod .\perlvms.pod
	copy ..\README.win32 .\perlwin32.pod
	copy ..\README.netware .\perlnw5.pod
	$(MAKE) -f ..\win32\pod.mak converters
	cd ..\netware
	$(MINIPERL) $(PL2BAT) $(UTILS)

distclean: clean nwclean
	-del /f $(PERLIMPLIB) ..\miniperl.lib $(MINIMOD)
	-del /f *.def *.map
	-del /f $(EXTENSION_C) $(DYNALOADER).c $(ERRNO).pm
	-del /f $(EXTDIR)\DynaLoader\dl_netware.xs
	-del /f $(LIBDIR)\.exists $(LIBDIR)\attrs.pm $(LIBDIR)\DynaLoader.pm
	-del /f $(LIBDIR)\XSLoader.pm
	-del /f $(LIBDIR)\Fcntl.pm $(LIBDIR)\IO.pm $(LIBDIR)\Opcode.pm
	-del /f $(LIBDIR)\ops.pm $(LIBDIR)\Safe.pm $(LIBDIR)\Thread.pm
	-del /f $(LIBDIR)\SDBM_File.pm $(LIBDIR)\Socket.pm $(LIBDIR)\POSIX.pm
	-del /f $(LIBDIR)\B.pm $(LIBDIR)\O.pm $(LIBDIR)\re.pm
	-del /f $(LIBDIR)\Data\Dumper.pm $(LIBDIR)\ByteLoader.pm
	-del /f $(LIBDIR)\Devel\Peek.pm $(LIBDIR)\Devel\DProf.pm
	-del /f $(LIBDIR)\File\Glob.pm
	-rmdir /s /q $(LIBDIR)\IO || rmdir /s $(LIBDIR)\IO
	-rmdir /s /q $(LIBDIR)\Thread || rmdir /s $(LIBDIR)\Thread
	-rmdir /s /q $(LIBDIR)\B || rmdir /s $(LIBDIR)\B
	-rmdir /s /q $(LIBDIR)\Data || rmdir /s $(LIBDIR)\Data
	-del /f $(PODDIR)\*.html
	-del /f $(PODDIR)\*.bat
	cd ..\utils
	-del /f h2ph splain perlbug pl2pm c2ph h2xs perldoc dprofpp
	-del /f *.bat
	cd ..\netware
	cd ..\x2p
	-del /f find2perl s2p
	-del /f *.bat
	-del *.obj *.map *.link *.xdc *.err
	cd ..\netware
	-del /f ..\config.sh ..\splittree.pl dlutils.c config.h.new
	-del /f $(CONFIGPM)
	-del /f bin\*.bat
	cd $(EXTDIR)
	-del /s *.lib *.def *.map *.pdb *.bs Makefile *$(o) pm_to_blib *.xdc *.err
	cd ..\netware
!if "$(NW_EXTNS)"=="yes"
	cd cgi2perl
	-del *.obj *.bs Makefile *$(o) *.c pm_to_blib *.xdc *.err
	cd ..
!endif
	-rmdir /s /q $(AUTODIR) || rmdir /s $(AUTODIR)
	-rmdir /s /q $(COREDIR) || rmdir /s $(COREDIR)
	-del ..\config.sh

installwin:
	$(MINIPERL) -I..\lib ..\installperl

install : utils installwin

installnw:
	$(MINIPERL) -I..\lib ..\installperl -netware

install_tests :
	cd ..\t
	xcopy /f /r /i /s /d *.* $(INST_NW_TOP2)\scripts\t
	cd ..\lib
	xcopy /f /r /i /s /d *.t $(INST_NW_TOP2)\scripts\t\lib
	cd ..\ext
	xcopy /f /r /i /s /d *.t $(INST_NW_TOP2)\scripts\t\ext
	cd ..\netware\t
	xcopy /f /r /i /s /d *.pl $(INST_NW_TOP2)\scripts\t
	cd ..

nwinstall: utils installnw install_tests

inst_lib : $(CONFIGPM)
	copy ..\win32\splittree.pl .. 
	$(MINIPERL) -I..\lib ..\splittree.pl "../LIB" $(AUTODIR)
	$(RCOPY) ..\lib $(INST_LIB)\*.*

clean : 
	-@erase miniperlmain$(o)
	-@erase /f config.h
	-@erase $(DLL_OBJ)
	-@erase ..\*$(o) ..\*.lib ..\*.exp *$(o) *.lib *.exp *.res
	-@erase ..\t\*.exe ..\t\*.dll ..\t\*.bat
	-@erase ..\x2p\*.nlm ..\x2p\*.bat

