#
# Makefile to build perl on Windows using GNU make + gcc + MinGW.
#
# This is set up to build a perl.exe that runs off a shared library
# (perl523.dll).  Also makes individual DLLs for the XS extensions.
#
# The easiest way to customize the build process is to use parameters like this:
#
# c:\dev\perlsrc\win32> gmake INST_TOP=c:\sw\perl CCHOME=c:\sw\mingw USE_64_BIT_INT=define


##
## Make sure you read README.win32 *before* you mess with anything here!
##

#
# We set this to point to cmd.exe in case GNU Make finds sh.exe in the path.
# Comment this line out if necessary
#
SHELL := cmd.exe

# define whether you want to use native gcc compiler or cross-compiler
# possible values: gcc
#                  i686-w64-mingw32-gcc
#                  x86_64-w64-mingw32-gcc
GCCBIN := gcc

ifeq ($(GCCBIN),x86_64-w64-mingw32-gcc)
GCCCROSS := x86_64-w64-mingw32
endif
ifeq ($(GCCBIN),i686-w64-mingw32-gcc)
GCCCROSS := i686-w64-mingw32
endif

GCCTARGET := $(shell $(GCCBIN) -dumpmachine)
GCCVER1   := $(shell for /f "delims=. tokens=1,2,3" %%i in ('gcc -dumpversion') do echo %%i)
GCCVER2   := $(shell for /f "delims=. tokens=1,2,3" %%i in ('gcc -dumpversion') do echo %%j)
GCCVER3   := $(shell for /f "delims=. tokens=1,2,3" %%i in ('gcc -dumpversion') do echo %%k)

ifeq ($(GCCTARGET),x86_64-w64-mingw32)
WIN64 := define
ARCHITECTURE := x64
endif
ifeq ($(GCCTARGET),i686-w64-mingw32)
WIN64 := undef
ARCHITECTURE := x86
endif

##
## Build configuration.  Edit the values below to suit your needs.
##

#
# Set these to wherever you want "gmake install" to put your
# newly built perl.
#
INST_DRV := c:
INST_TOP := $(INST_DRV)\perl

#
# Comment this out if you DON'T want your perl installation to be versioned.
# This means that the new installation will overwrite any files from the
# old installation at the same INST_TOP location.  Leaving it enabled is
# the safest route, as perl adds the extra version directory to all the
# locations it installs files to.  If you disable it, an alternative
# versioned installation can be obtained by setting INST_TOP above to a
# path that includes an arbitrary version string.
#
#INST_VER	:= \5.23.8

#
# Comment this out if you DON'T want your perl installation to have
# architecture specific components.  This means that architecture-
# specific files will be installed along with the architecture-neutral
# files.  Leaving it enabled is safer and more flexible, in case you
# want to build multiple flavors of perl and install them together in
# the same location.  Commenting it out gives you a simpler
# installation that is easier to understand for beginners.
#
#INST_ARCH	:= \$(ARCHNAME)

#
# Uncomment this if you want perl to run
# 	$Config{sitelibexp}\sitecustomize.pl
# before anything else.  This script can then be set up, for example,
# to add additional entries to @INC.
#
#USE_SITECUST	:= define

#
# uncomment to enable multiple interpreters.  This is needed for fork()
# emulation and for thread support, and is auto-enabled by USE_IMP_SYS
# and USE_ITHREADS below.
#
USE_MULTI	:= define

#
# Interpreter cloning/threads; now reasonably complete.
# This should be enabled to get the fork() emulation.  This needs (and
# will auto-enable) USE_MULTI above.
#
USE_ITHREADS	:= define

#
# uncomment to enable the implicit "host" layer for all system calls
# made by perl.  This is also needed to get fork().  This needs (and
# will auto-enable) USE_MULTI above.
#
USE_IMP_SYS	:= define

#
# Comment out next assign to disable perl's I/O subsystem and use compiler's
# stdio for IO - depending on your compiler vendor and run time library you may
# then get a number of fails from make test i.e. bugs - complain to them not us ;-).
# You will also be unable to take full advantage of perl5.8's support for multiple
# encodings and may see lower IO performance. You have been warned.
#
USE_PERLIO	:= define

#
# Comment this out if you don't want to enable large file support for
# some reason.  Should normally only be changed to maintain compatibility
# with an older release of perl.
#
USE_LARGE_FILES	:= define

#
# Uncomment this if you're building a 32-bit perl and want 64-bit integers.
# (If you're building a 64-bit perl then you will have 64-bit integers whether
# or not this is uncommented.)
# Note: This option is not supported in 32-bit MSVC60 builds.
#
#USE_64_BIT_INT	:= define

#
# Uncomment this if you want to support the use of long doubles.
#
#USE_LONG_DOUBLE :=define

#
# uncomment next line if you want debug version of perl (big,slow)
# If not enabled, we automatically try to use maximum optimization
# with all compilers that are known to have a working optimizer.
#
#CFG		:= Debug

#
# uncomment to enable linking with setargv.obj under the Visual C
# compiler. Setting this options enables perl to expand wildcards in
# arguments, but it may be harder to use alternate methods like
# File::DosGlob that are more powerful.  This option is supported only with
# Visual C.
#
#USE_SETARGV	:= define

#
# set this if you wish to use perl's malloc
# WARNING: Turning this on/off WILL break binary compatibility with extensions
# you may have compiled with/without it.  Be prepared to recompile all
# extensions if you change the default.  Currently, this cannot be enabled
# if you ask for USE_IMP_SYS above.
#
#PERL_MALLOC	:= define

#
# set this to enable debugging mstats
# This must be enabled to use the Devel::Peek::mstat() function.  This cannot
# be enabled without PERL_MALLOC as well.
#
#DEBUG_MSTATS	:= define

#
# set this to additionally provide a statically linked perl-static.exe.
# Note that dynamic loading will not work with this perl, so you must
# include required modules statically using the STATIC_EXT or ALL_STATIC
# variables below. A static library perl523s.lib will also be created.
# Ordinary perl.exe is not affected by this option.
#
#BUILD_STATIC	:= define

#
# in addition to BUILD_STATIC the option ALL_STATIC makes *every*
# extension get statically built
# This will result in a very large perl executable, but the main purpose
# is to have proper linking set so as to be able to create miscellaneous
# executables with different built-in extensions
#
#ALL_STATIC	:= define

#
# set the install locations of the compiler include/libraries
# Running VCVARS32.BAT is *required* when using Visual C.
# Some versions of Visual C don't define MSVCDIR in the environment,
# so you may have to set CCHOME explicitly (spaces in the path name should
# not be quoted)
#
CCHOME		:= C:\MinGW

#
# Following sets $Config{incpath} and $Config{libpth}
#

ifneq ($(GCCCROSS),)
CCINCDIR := $(CCHOME)\$(GCCCROSS)\include
CCLIBDIR := $(CCHOME)\$(GCCCROSS)\lib
CCDLLDIR := $(CCLIBDIR)
ARCHPREFIX := $(GCCCROSS)-
else
CCINCDIR := $(CCHOME)\include
CCLIBDIR := $(CCHOME)\lib
CCDLLDIR := $(CCHOME)\bin
ARCHPREFIX :=
endif

#
# Additional compiler flags can be specified here.
#
BUILDOPT	:= $(BUILDOPTEXTRA)

#
# This should normally be disabled.  Enabling it will disable the File::Glob
# implementation of CORE::glob.
#
#BUILDOPT	+= -DPERL_EXTERNAL_GLOB

#
# Perl needs to read scripts in text mode so that the DATA filehandle
# works correctly with seek() and tell(), or around auto-flushes of
# all filehandles (e.g. by system(), backticks, fork(), etc).
#
# The current version on the ByteLoader module on CPAN however only
# works if scripts are read in binary mode.  But before you disable text
# mode script reading (and break some DATA filehandle functionality)
# please check first if an updated ByteLoader isn't available on CPAN.
#
BUILDOPT	+= -DPERL_TEXTMODE_SCRIPTS

#
# specify semicolon-separated list of extra directories that modules will
# look for libraries (spaces in path names need not be quoted)
#
EXTRALIBDIRS	:=

#
# set this to your email address (perl will guess a value from
# from your loginname and your hostname, which may not be right)
#
#EMAIL		:=

##
## Build configuration ends.
##

##################### CHANGE THESE ONLY IF YOU MUST #####################

PERL_MALLOC	?= undef
DEBUG_MSTATS	?= undef

USE_SITECUST	?= undef
USE_MULTI	?= undef
USE_ITHREADS	?= undef
USE_IMP_SYS	?= undef
USE_PERLIO	?= undef
USE_LARGE_FILES	?= undef
USE_64_BIT_INT	?= undef
USE_LONG_DOUBLE	?= undef

ifeq ($(USE_IMP_SYS),define)
PERL_MALLOC	= undef
endif

ifeq ($(PERL_MALLOC),undef)
DEBUG_MSTATS	= undef
endif

ifeq ($(DEBUG_MSTATS),define)
BUILDOPT	+= -DPERL_DEBUGGING_MSTATS
endif

ifeq ("$(USE_IMP_SYS) $(USE_MULTI)","define undef")
USE_MULTI	= define
endif

ifeq ("$(USE_ITHREADS) $(USE_MULTI)","define undef")
USE_MULTI	= define
endif

ifeq ($(USE_SITECUST),define)
BUILDOPT	+= -DUSE_SITECUSTOMIZE
endif

ifneq ($(USE_MULTI),undef)
BUILDOPT	+= -DPERL_IMPLICIT_CONTEXT
endif

ifneq ($(USE_IMP_SYS),undef)
BUILDOPT	+= -DPERL_IMPLICIT_SYS
endif

ifeq ($(WIN64),define)
USE_64_BIT_INT	= define
endif

ifeq ($(USE_MULTI),define)
ARCHNAME	= MSWin32-$(ARCHITECTURE)-multi
else
ifeq ($(USE_PERLIO),define)
ARCHNAME	= MSWin32-$(ARCHITECTURE)-perlio
else
ARCHNAME	= MSWin32-$(ARCHITECTURE)
endif
endif

ifeq ($(USE_PERLIO),define)
BUILDOPT	+= -DUSE_PERLIO
endif

ifeq ($(USE_ITHREADS),define)
ARCHNAME	:= $(ARCHNAME)-thread
endif

ifneq ($(WIN64),define)
ifeq ($(USE_64_BIT_INT),define)
ARCHNAME	:= $(ARCHNAME)-64int
endif
endif

ifeq ($(USE_LONG_DOUBLE),define)
ARCHNAME	:= $(ARCHNAME)-ld
endif

ARCHDIR		= ..\lib\$(ARCHNAME)
COREDIR		= ..\lib\CORE
AUTODIR		= ..\lib\auto
LIBDIR		= ..\lib
EXTDIR		= ..\ext
DISTDIR		= ..\dist
CPANDIR		= ..\cpan
PODDIR		= ..\pod
HTMLDIR		= .\html

#
INST_SCRIPT	= $(INST_TOP)$(INST_VER)\bin
INST_BIN	= $(INST_SCRIPT)$(INST_ARCH)
INST_LIB	= $(INST_TOP)$(INST_VER)\lib
INST_ARCHLIB	= $(INST_LIB)$(INST_ARCH)
INST_COREDIR	= $(INST_ARCHLIB)\CORE
INST_HTML	= $(INST_TOP)$(INST_VER)\html

#
# Programs to compile, build .lib files and link
#

MINIBUILDOPT    :=

CC		= $(ARCHPREFIX)gcc
LINK32		= $(ARCHPREFIX)g++
LIB32		= $(ARCHPREFIX)ar rc
IMPLIB		= $(ARCHPREFIX)dlltool
RSC		= $(ARCHPREFIX)windres

ifeq ($(USE_LONG_DOUBLE),define)
BUILDOPT        += -D__USE_MINGW_ANSI_STDIO
MINIBUILDOPT    += -D__USE_MINGW_ANSI_STDIO
endif

# If you are using GCC, 4.3 or later by default we add the -fwrapv option.
# See https://rt.perl.org/Ticket/Display.html?id=121505
#
GCCWRAPV := $(shell if "$(GCCVER1)"=="4" (if "$(GCCVER2)" geq "3" echo define) else if "$(GCCVER1)" geq "5" (echo define))

ifeq ($(GCCWRAPV),define)
BUILDOPT        += -fwrapv
MINIBUILDOPT    += -fwrapv
endif

i = .i
o = .o
a = .a

#
# Options
#

INCLUDES	= -I.\include -I. -I.. -I$(COREDIR)
DEFINES		= -DWIN32
ifeq ($(WIN64),define)
DEFINES		+= -DWIN64 -DCONSERVATIVE
endif
LOCDEFS		= -DPERLDLL -DPERL_CORE
SUBSYS		= console
CXX_FLAG	= -xc++
LIBC		=
LIBFILES	= $(LIBC) \
		  -lmoldname -lkernel32 -luser32 -lgdi32 \
		  -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 \
		  -loleaut32 -lnetapi32 -luuid -lws2_32 -lmpr \
		  -lwinmm -lversion -lodbc32 -lodbccp32 -lcomctl32

ifeq ($(CFG),Debug)
OPTIMIZE	= -g -O2 -DDEBUGGING
LINK_DBG	= -g
else
OPTIMIZE	= -s -O2
LINK_DBG	= -s
endif

EXTRACFLAGS	=
CFLAGS		= $(EXTRACFLAGS) $(INCLUDES) $(DEFINES) $(LOCDEFS) $(OPTIMIZE)
LINK_FLAGS	= $(LINK_DBG) -L"$(INST_COREDIR)" -L"$(CCLIBDIR)"
OBJOUT_FLAG	= -o
EXEOUT_FLAG	= -o
LIBOUT_FLAG	=

BUILDOPT	+= -fno-strict-aliasing -mms-bitfields
MINIBUILDOPT	+= -fno-strict-aliasing
CFLAGS_O	= $(CFLAGS) $(BUILDOPT)

# used to allow local linking flags that are not propogated into Config.pm,
# currently unused
#   -- BKS, 12-12-1999
PRIV_LINK_FLAGS	=
BLINK_FLAGS	= $(PRIV_LINK_FLAGS) $(LINK_FLAGS)

#################### do not edit below this line #######################
############# NO USER-SERVICEABLE PARTS BEYOND THIS POINT ##############

%$(o): %.c
	$(CC) -c -I$(<D) $(CFLAGS_O) $(OBJOUT_FLAG)$@ $<

%.i: %.c
	$(CC) -c -I$(<D) $(CFLAGS_O) -E $< >$@

%.c: %.y
	$(NOOP)

%.dll: %$(o)
	$(LINK32) -o $@ $(BLINK_FLAGS) $< $(LIBFILES)
	$(IMPLIB) --input-def $(*F).def --output-lib $(*F).a $@

%.res: %.rc
	$(RSC) --use-temp-file --include-dir=. --include-dir=.. -O COFF -D INCLUDE_MANIFEST -i $< -o $@

#
# various targets
MINIPERL	= ..\miniperl.exe
MINIDIR		= mini
PERLEXE		= ..\perl.exe
WPERLEXE	= ..\wperl.exe
PERLEXESTATIC	= ..\perl-static.exe
STATICDIR	= .\static.tmp
GLOBEXE		= ..\perlglob.exe
CONFIGPM	= ..\lib\Config.pm ..\lib\Config_heavy.pl
GENUUDMAP	= ..\generate_uudmap.exe
ifeq ($(BUILD_STATIC),define)
PERLSTATIC	= static
else
ifeq ($(ALL_STATIC),define)
PERLSTATIC	= static
else
PERLSTATIC	=
endif
endif

# Unicode data files generated by mktables
UNIDATAFILES	 = ..\lib\unicore\Decomposition.pl ..\lib\unicore\TestProp.pl \
		   ..\lib\unicore\CombiningClass.pl ..\lib\unicore\Name.pl \
		   ..\lib\unicore\UCD.pl ..\lib\unicore\Name.pm            \
		   ..\lib\unicore\Heavy.pl ..\lib\unicore\mktables.lst

# Directories of Unicode data files generated by mktables
UNIDATADIR1	= ..\lib\unicore\To
UNIDATADIR2	= ..\lib\unicore\lib

PERLEXE_MANIFEST= .\perlexe.manifest
PERLEXE_ICO	= .\perlexe.ico
PERLEXE_RES	= .\perlexe.res
PERLDLL_RES	=

# Nominate a target which causes extensions to be re-built
# This used to be $(PERLEXE), but at worst it is the .dll that they depend
# on and really only the interface - i.e. the .def file used to export symbols
# from the .dll
PERLDEP = perldll.def


PL2BAT		= bin\pl2bat.pl

UTILS		=			\
		..\utils\h2ph		\
		..\utils\splain		\
		..\utils\perlbug	\
		..\utils\pl2pm 		\
		..\utils\c2ph		\
		..\utils\pstruct	\
		..\utils\h2xs		\
		..\utils\perldoc	\
		..\utils\perlivp	\
		..\utils\libnetcfg	\
		..\utils\enc2xs		\
		..\utils\piconv		\
		..\utils\corelist	\
		..\utils\cpan		\
		..\utils\xsubpp		\
		..\utils\pod2html	\
		..\utils\prove		\
		..\utils\ptar		\
		..\utils\ptardiff	\
		..\utils\ptargrep	\
		..\utils\zipdetails	\
		..\utils\shasum		\
		..\utils\instmodsh	\
		..\utils\json_pp	\
		bin\exetype.pl		\
		bin\runperl.pl		\
		bin\pl2bat.pl		\
		bin\perlglob.pl		\
		bin\search.pl

CFGSH_TMPL	= config.gc
CFGH_TMPL	= config_H.gc
PERLIMPLIB	= ..\libperl523$(a)
PERLSTATICLIB	= ..\libperl523s$(a)
INT64		= long long

# makedef.pl must be updated if this changes, and this should normally
# only change when there is an incompatible revision of the public API.
PERLDLL		= ..\perl523.dll

XCOPY		= xcopy /f /r /i /d /y
RCOPY		= xcopy /f /r /i /e /d /y
NOOP		= @rem

MICROCORE_SRC	=		\
		..\av.c		\
		..\caretx.c	\
		..\deb.c	\
		..\doio.c	\
		..\doop.c	\
		..\dquote.c	\
		..\dump.c	\
		..\globals.c	\
		..\gv.c		\
		..\mro_core.c	\
		..\hv.c		\
		..\locale.c	\
		..\keywords.c	\
		..\mathoms.c    \
		..\mg.c		\
		..\numeric.c	\
		..\op.c		\
		..\pad.c	\
		..\perl.c	\
		..\perlapi.c	\
		..\perly.c	\
		..\pp.c		\
		..\pp_ctl.c	\
		..\pp_hot.c	\
		..\pp_pack.c	\
		..\pp_sort.c	\
		..\pp_sys.c	\
		..\reentr.c	\
		..\regcomp.c	\
		..\regexec.c	\
		..\run.c	\
		..\scope.c	\
		..\sv.c		\
		..\taint.c	\
		..\time64.c	\
		..\toke.c	\
		..\universal.c	\
		..\utf8.c	\
		..\util.c

EXTRACORE_SRC	+= perllib.c

ifeq ($(PERL_MALLOC),define)
EXTRACORE_SRC	+= ..\malloc.c
endif

EXTRACORE_SRC	+= ..\perlio.c

WIN32_SRC	=		\
		.\win32.c	\
		.\win32sck.c	\
		.\win32thread.c	\
		.\fcrypt.c

# We need this for miniperl build unless we override canned
# config.h #define building mini\*
#ifeq ($(USE_PERLIO)" == "define"
WIN32_SRC	+= .\win32io.c
#endif

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
		..\hv_func.h	\
		..\iperlsys.h	\
		..\mg.h		\
		..\nostdio.h	\
		..\op.h		\
		..\opcode.h	\
		..\perl.h	\
		..\perlapi.h	\
		..\perlsdio.h	\
		..\perly.h	\
		..\pp.h		\
		..\proto.h	\
		..\regcomp.h	\
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
		.\include\dirent.h	\
		.\include\netdb.h	\
		.\include\sys\errno2.h	\
		.\include\sys\socket.h	\
		.\win32.h

CORE_H		= $(CORE_NOCFG_H) .\config.h ..\git_version.h

UUDMAP_H	= ..\uudmap.h
BITCOUNT_H	= ..\bitcount.h
MG_DATA_H	= ..\mg_data.h
GENERATED_HEADERS = $(UUDMAP_H) $(BITCOUNT_H) $(MG_DATA_H)

MICROCORE_OBJ	= $(MICROCORE_SRC:.c=.o)
CORE_OBJ	= $(MICROCORE_OBJ) $(EXTRACORE_SRC:.c=.o)
WIN32_OBJ	= $(WIN32_SRC:.c=.o)

MINICORE_OBJ	= $(subst ..\,mini\,$(MICROCORE_OBJ))	\
		  $(MINIDIR)\miniperlmain$(o)	\
		  $(MINIDIR)\perlio$(o)
MINIWIN32_OBJ	= $(subst .\,mini\,$(WIN32_OBJ))
MINI_OBJ	= $(MINICORE_OBJ) $(MINIWIN32_OBJ)
DLL_OBJ		= $(DYNALOADER)
GENUUDMAP_OBJ	= $(GENUUDMAP:.exe=.o)

PERLDLL_OBJ	= $(CORE_OBJ)
PERLEXE_OBJ	= perlmain$(o)
PERLEXEST_OBJ	= perlmainst$(o)

PERLDLL_OBJ	+= $(WIN32_OBJ) $(DLL_OBJ)

ifneq ($(USE_SETARGV),)
SETARGV_OBJ	= setargv$(o)
endif

ifeq ($(ALL_STATIC),define)
# some exclusions, unfortunately, until fixed:
#  - MakeMaker isn't capable enough for SDBM_File (small bug)
STATIC_EXT	= * !SDBM_File
else
# specify static extensions here, for example:
# (be sure to include Win32CORE to load Win32 on demand)
#STATIC_EXT	= Win32CORE Cwd Compress/Raw/Zlib
STATIC_EXT	= Win32CORE
endif

DYNALOADER	= ..\DynaLoader$(o)

# vars must be separated by "\t+~\t+", since we're using the tempfile
# version of config_sh.pl (we were overflowing someone's buffer by
# trying to fit them all on the command line)
#	-- BKS 10-17-1999
CFG_VARS	=					\
		"INST_TOP=$(INST_TOP)"			\
		"INST_VER=$(INST_VER)"			\
		"INST_ARCH=$(INST_ARCH)"		\
		"archname=$(ARCHNAME)"			\
		"cc=$(CC)"				\
		"ld=$(LINK32)"				\
		"ccflags=$(EXTRACFLAGS) $(OPTIMIZE) $(DEFINES) $(BUILDOPT)" \
		"cf_email=$(EMAIL)"			\
		"d_mymalloc=$(PERL_MALLOC)"		\
		"libs=$(LIBFILES)"			\
		"incpath=$(CCINCDIR)"			\
		"libperl=$(subst ..\,,$(PERLIMPLIB))"	\
		"libpth=$(CCLIBDIR);$(EXTRALIBDIRS)"	\
		"libc=$(LIBC)"				\
		"make=$(MAKE)"				\
		"_o=$(o)"				\
		"obj_ext=$(o)"				\
		"_a=$(a)"				\
		"lib_ext=$(a)"				\
		"static_ext=$(STATIC_EXT)"		\
		"usethreads=$(USE_ITHREADS)"		\
		"useithreads=$(USE_ITHREADS)"		\
		"usemultiplicity=$(USE_MULTI)"		\
		"useperlio=$(USE_PERLIO)"		\
		"use64bitint=$(USE_64_BIT_INT)"		\
		"uselongdouble=$(USE_LONG_DOUBLE)"	\
		"uselargefiles=$(USE_LARGE_FILES)"	\
		"usesitecustomize=$(USE_SITECUST)"	\
		"LINK_FLAGS=$(LINK_FLAGS)"		\
		"optimize=$(OPTIMIZE)"			\
		"ARCHPREFIX=$(ARCHPREFIX)"		\
		"WIN64=$(WIN64)"

#
# Top targets
#

.PHONY: all info

all : info .\config.h ..\git_version.h $(GLOBEXE) $(MINIPERL)	\
	$(CONFIGPM) $(UNIDATAFILES) MakePPPort			\
	$(PERLEXE) Extensions Extensions_nonxs $(PERLSTATIC)

info :
	@echo # GCCBIN=$(GCCBIN)
	@echo # GCCVER=$(GCCVER1).$(GCCVER2).$(GCCVER3)
	@echo # GCCTARGET=$(GCCTARGET)
	@echo # GCCCROSS=$(GCCCROSS)
	@echo # WIN64=$(WIN64)
	@echo # ARCHITECTURE=$(ARCHITECTURE)
	@echo # ARCHNAME=$(ARCHNAME)
	@echo # MAKE=$(MAKE)
ifeq ($(GCCTARGET),)
	@echo Unable to detect gcc and/or architecture!
	@exit 1
endif


regnodes : ..\regnodes.h

..\regcomp$(o) : ..\regnodes.h ..\regcharclass.h

..\regexec$(o) : ..\regnodes.h ..\regcharclass.h

reonly : regnodes .\config.h ..\git_version.h $(GLOBEXE) $(MINIPERL)	\
	$(CONFIGPM) $(UNIDATAFILES) $(PERLEXE)				\
	Extensions_reonly

static: $(PERLEXESTATIC)

#----------------------------------------------------------------

$(GLOBEXE) : perlglob$(o)
	$(LINK32) $(BLINK_FLAGS) -mconsole -o $@ perlglob$(o) $(LIBFILES)

perlglob$(o)  : perlglob.c

#
# Copy the template config.h and set configurables at the end of it
# as per the options chosen and compiler used.
# Note: This config.h is only used to build miniperl.exe anyway, but
# it's as well to have its options correct to be sure that it builds
# and so that it's "-V" options are correct for use by makedef.pl. The
# real config.h used to build perl.exe is generated from the top-level
# config_h.SH by config_h.PL (run by miniperl.exe).
#
.\config.h : $(CFGH_TMPL) $(CORE_NOCFG_H)
	-del /f config.h
	copy $(CFGH_TMPL) config.h
	@echo.>>$@
	@echo #ifndef _config_h_footer_>>$@
	@echo #define _config_h_footer_>>$@
	@echo #undef Off_t>>$@
	@echo #undef LSEEKSIZE>>$@
	@echo #undef Off_t_size>>$@
	@echo #undef PTRSIZE>>$@
	@echo #undef SSize_t>>$@
	@echo #undef HAS_ATOLL>>$@
	@echo #undef HAS_STRTOLL>>$@
	@echo #undef HAS_STRTOULL>>$@
	@echo #undef Size_t_size>>$@
	@echo #undef IVTYPE>>$@
	@echo #undef UVTYPE>>$@
	@echo #undef IVSIZE>>$@
	@echo #undef UVSIZE>>$@
	@echo #undef NV_PRESERVES_UV>>$@
	@echo #undef NV_PRESERVES_UV_BITS>>$@
	@echo #undef IVdf>>$@
	@echo #undef UVuf>>$@
	@echo #undef UVof>>$@
	@echo #undef UVxf>>$@
	@echo #undef UVXf>>$@
	@echo #undef USE_64_BIT_INT>>$@
	@echo #undef Gconvert>>$@
	@echo #undef HAS_FREXPL>>$@
	@echo #undef HAS_ISNANL>>$@
	@echo #undef HAS_MODFL>>$@
	@echo #undef HAS_MODFL_PROTO>>$@
	@echo #undef HAS_SQRTL>>$@
	@echo #undef HAS_STRTOLD>>$@
	@echo #undef PERL_PRIfldbl>>$@
	@echo #undef PERL_PRIgldbl>>$@
	@echo #undef PERL_PRIeldbl>>$@
	@echo #undef PERL_SCNfldbl>>$@
	@echo #undef NVTYPE>>$@
	@echo #undef NVSIZE>>$@
	@echo #undef LONG_DOUBLESIZE>>$@
	@echo #undef NV_OVERFLOWS_INTEGERS_AT>>$@
	@echo #undef NVef>>$@
	@echo #undef NVff>>$@
	@echo #undef NVgf>>$@
	@echo #undef USE_LONG_DOUBLE>>$@
ifeq ($(USE_LARGE_FILES),define)
	@echo #define Off_t $(INT64)>>$@
	@echo #define LSEEKSIZE ^8>>$@
	@echo #define Off_t_size ^8>>$@
else
	@echo #define Off_t long>>$@
	@echo #define LSEEKSIZE ^4>>$@
	@echo #define Off_t_size ^4>>$@
endif
ifeq ($(WIN64),define)
	@echo #define PTRSIZE ^8>>$@
	@echo #define SSize_t $(INT64)>>$@
	@echo #define HAS_ATOLL>>$@
	@echo #define HAS_STRTOLL>>$@
	@echo #define HAS_STRTOULL>>$@
	@echo #define Size_t_size ^8>>$@
else
	@echo #define PTRSIZE ^4>>$@
	@echo #define SSize_t int>>$@
	@echo #undef HAS_ATOLL>>$@
	@echo #undef HAS_STRTOLL>>$@
	@echo #undef HAS_STRTOULL>>$@
	@echo #define Size_t_size ^4>>$@
endif
ifeq ($(USE_64_BIT_INT),define)
	@echo #define IVTYPE $(INT64)>>$@
	@echo #define UVTYPE unsigned $(INT64)>>$@
	@echo #define IVSIZE ^8>>$@
	@echo #define UVSIZE ^8>>$@
ifeq ($(USE_LONG_DOUBLE),define)
	@echo #define NV_PRESERVES_UV>>$@
	@echo #define NV_PRESERVES_UV_BITS 64>>$@
else
	@echo #undef NV_PRESERVES_UV>>$@
	@echo #define NV_PRESERVES_UV_BITS 53>>$@
endif
	@echo #define IVdf "I64d">>$@
	@echo #define UVuf "I64u">>$@
	@echo #define UVof "I64o">>$@
	@echo #define UVxf "I64x">>$@
	@echo #define UVXf "I64X">>$@
	@echo #define USE_64_BIT_INT>>$@
else
	@echo #define IVTYPE long>>$@
	@echo #define UVTYPE unsigned long>>$@
	@echo #define IVSIZE ^4>>$@
	@echo #define UVSIZE ^4>>$@
	@echo #define NV_PRESERVES_UV>>$@
	@echo #define NV_PRESERVES_UV_BITS 32>>$@
	@echo #define IVdf "ld">>$@
	@echo #define UVuf "lu">>$@
	@echo #define UVof "lo">>$@
	@echo #define UVxf "lx">>$@
	@echo #define UVXf "lX">>$@
	@echo #undef USE_64_BIT_INT>>$@
endif
ifeq ($(USE_LONG_DOUBLE),define)
	@echo #define Gconvert(x,n,t,b) sprintf((b),"%%.*""Lg",(n),(x))>>$@
	@echo #define HAS_FREXPL>>$@
	@echo #define HAS_ISNANL>>$@
	@echo #define HAS_MODFL>>$@
	@echo #define HAS_MODFL_PROTO>>$@
	@echo #define HAS_SQRTL>>$@
	@echo #define HAS_STRTOLD>>$@
	@echo #define PERL_PRIfldbl "Lf">>$@
	@echo #define PERL_PRIgldbl "Lg">>$@
	@echo #define PERL_PRIeldbl "Le">>$@
	@echo #define PERL_SCNfldbl "Lf">>$@
	@echo #define NVTYPE long double>>$@
ifeq ($(WIN64),define)
	@echo #define NVSIZE ^16>>$@
	@echo #define LONG_DOUBLESIZE ^16>>$@
else
	@echo #define NVSIZE ^12>>$@
	@echo #define LONG_DOUBLESIZE ^12>>$@
endif
	@echo #define NV_OVERFLOWS_INTEGERS_AT 256.0*256.0*256.0*256.0*256.0*256.0*256.0*2.0*2.0*2.0*2.0*2.0*2.0*2.0*2.0>>$@
	@echo #define NVef "Le">>$@
	@echo #define NVff "Lf">>$@
	@echo #define NVgf "Lg">>$@
	@echo #define USE_LONG_DOUBLE>>$@
else
	@echo #define Gconvert(x,n,t,b) sprintf((b),"%%.*g",(n),(x))>>$@
	@echo #undef HAS_FREXPL>>$@
	@echo #undef HAS_ISNANL>>$@
	@echo #undef HAS_MODFL>>$@
	@echo #undef HAS_MODFL_PROTO>>$@
	@echo #undef HAS_SQRTL>>$@
	@echo #undef HAS_STRTOLD>>$@
	@echo #undef PERL_PRIfldbl>>$@
	@echo #undef PERL_PRIgldbl>>$@
	@echo #undef PERL_PRIeldbl>>$@
	@echo #undef PERL_SCNfldbl>>$@
	@echo #define NVTYPE double>>$@
	@echo #define NVSIZE ^8>>$@
	@echo #define LONG_DOUBLESIZE ^8>>$@
	@echo #define NV_OVERFLOWS_INTEGERS_AT 256.0*256.0*256.0*256.0*256.0*256.0*2.0*2.0*2.0*2.0*2.0>>$@
	@echo #define NVef "e">>$@
	@echo #define NVff "f">>$@
	@echo #define NVgf "g">>$@
	@echo #undef USE_LONG_DOUBLE>>$@
endif
	@echo #endif>>$@

..\git_version.h : $(MINIPERL) ..\make_patchnum.pl
	cd .. && miniperl -Ilib make_patchnum.pl

# make sure that we recompile perl.c if the git version changes
..\perl$(o) : ..\git_version.h

..\config.sh : $(CFGSH_TMPL) config_sh.PL FindExt.pm $(MINIPERL)
	$(MINIPERL) -I..\lib config_sh.PL $(CFG_VARS) $(CFGSH_TMPL) > ..\config.sh

# This target is for when changes to the main config.sh happen.
# Edit config.gc, then make perl using GCC in a minimal configuration (i.e.
# with MULTI, ITHREADS, IMP_SYS, LARGE_FILES and PERLIO off), then make
# this target to regenerate config_H.gc.
regen_config_h:
	$(MINIPERL) -I..\lib config_sh.PL $(CFG_VARS)) $(CFGSH_TMPL) > ..\config.sh
	$(MINIPERL) -I..\lib ..\configpm --chdir=..
	-del /f $(CFGH_TMPL)
	-$(MINIPERL) -I..\lib config_h.PL "ARCHPREFIX=$(ARCHPREFIX)"
	rename config.h $(CFGH_TMPL)

$(CONFIGPM) : $(MINIPERL) ..\config.sh config_h.PL
	$(MINIPERL) -I..\lib ..\configpm --chdir=..
	if exist lib\* $(RCOPY) "lib\*.*" ..\lib\$(NULL)
	$(XCOPY) "..\*.h" $(COREDIR)\$(NULL)
	$(XCOPY) "*.h" $(COREDIR)\$(NULL)
	$(RCOPY) include $(COREDIR)\$(NULL)
	$(MINIPERL) -I..\lib config_h.PL "ARCHPREFIX=$(ARCHPREFIX)" \
	    || $(MAKE) $(MAKEMACROS) $(CONFIGPM) $(MAKEFILE)

# See the comment in Makefile.SH explaining this seemingly cranky ordering
$(MINIPERL) : ..\lib\buildcustomize.pl

..\lib\buildcustomize.pl : $(MINIDIR) $(MINI_OBJ) $(CRTIPMLIBS) ..\write_buildcustomize.pl
	$(LINK32) -mconsole -o $(MINIPERL) $(BLINK_FLAGS) $(MINI_OBJ) $(LIBFILES)
	$(MINIPERL) -I..\lib -f ..\write_buildcustomize.pl ..

$(MINIDIR) :
	if not exist "$(MINIDIR)" mkdir "$(MINIDIR)"

$(MINICORE_OBJ) : $(CORE_NOCFG_H)
	$(CC) -c $(CFLAGS) $(MINIBUILDOPT) -DPERL_EXTERNAL_GLOB -DPERL_IS_MINIPERL $(OBJOUT_FLAG)$@ ..\$(*F).c

$(MINIWIN32_OBJ) : $(CORE_NOCFG_H)
	$(CC) -c $(CFLAGS) $(MINIBUILDOPT) -DPERL_IS_MINIPERL $(OBJOUT_FLAG)$@ $(*F).c

# -DPERL_IMPLICIT_SYS needs C++ for perllib.c
# rules wrapped in .IFs break Win9X build (we end up with unbalanced []s unless
# unless the .IF is true), so instead we use a else with the default.
# This is the only file that depends on perlhost.h, vmem.h, and vdir.h

perllib$(o)	: perllib.c .\perlhost.h .\vdir.h .\vmem.h
ifeq ($(USE_IMP_SYS),define)
	$(CC) -c -I. $(CFLAGS_O) $(CXX_FLAG) $(OBJOUT_FLAG)$@ perllib.c
else
	$(CC) -c -I. $(CFLAGS_O) $(OBJOUT_FLAG)$@ perllib.c
endif

# 1. we don't want to rebuild miniperl.exe when config.h changes
# 2. we don't want to rebuild miniperl.exe with non-default config.h
# 3. we can't have miniperl.exe depend on git_version.h, as miniperl creates it
$(MINI_OBJ)	: $(CORE_NOCFG_H)

$(WIN32_OBJ)	: $(CORE_H)

$(CORE_OBJ)	: $(CORE_H)

$(DLL_OBJ)	: $(CORE_H)

perldll.def : $(MINIPERL) $(CONFIGPM) ..\embed.fnc ..\makedef.pl create_perllibst_h.pl
	$(MINIPERL) -I..\lib create_perllibst_h.pl
	$(MINIPERL) -I..\lib -w ..\makedef.pl PLATFORM=win32 $(OPTIMIZE) $(DEFINES) \
	$(BUILDOPT) CCTYPE=GCC TARG_DIR=..\ > perldll.def

$(PERLDLL): perldll.def $(PERLDLL_OBJ) $(PERLDLL_RES) Extensions_static
	$(LINK32) -mdll -o $@ -Wl,--base-file -Wl,perl.base $(BLINK_FLAGS) \
	   $(PERLDLL_OBJ) $(shell type Extensions_static) $(LIBFILES)
	$(IMPLIB) --output-lib $(PERLIMPLIB) \
		--dllname $(PERLDLL) \
		--def perldll.def \
		--base-file perl.base \
		--output-exp perl.exp
	$(LINK32) -mdll -o $@ $(BLINK_FLAGS) \
	    $(PERLDLL_OBJ) $(shell type Extensions_static) $(LIBFILES) perl.exp
	$(XCOPY) $(PERLIMPLIB) $(COREDIR)

$(PERLSTATICLIB): $(PERLDLL_OBJ) Extensions_static
	$(LIB32) $(LIB_FLAGS) $@ $(PERLDLL_OBJ)
	if exist $(STATICDIR) rmdir /s /q $(STATICDIR)
	for %%i in ($(shell type Extensions_static)) do \
		@mkdir $(STATICDIR) && cd $(STATICDIR) && \
		$(ARCHPREFIX)ar x ..\%%i && \
		$(ARCHPREFIX)ar q ..\$@ *$(o) && \
		cd .. && rmdir /s /q $(STATICDIR)
	$(XCOPY) $(PERLSTATICLIB) $(COREDIR)

$(PERLEXE_RES): perlexe.rc $(PERLEXE_MANIFEST) $(PERLEXE_ICO)

$(MINIDIR)\globals$(o) : $(GENERATED_HEADERS)

$(UUDMAP_H) $(MG_DATA_H) : $(BITCOUNT_H)

$(BITCOUNT_H) : $(GENUUDMAP)
	$(GENUUDMAP) $(GENERATED_HEADERS)

$(GENUUDMAP_OBJ) : ..\mg_raw.h

$(GENUUDMAP) : $(GENUUDMAP_OBJ)
	$(LINK32) -o $@ $(BLINK_FLAGS) $(GENUUDMAP_OBJ) $(LIBFILES)

perlmain.c : runperl.c
	copy runperl.c perlmain.c

perlmain$(o) : perlmain.c
	$(CC) $(subst -DPERLDLL,-UPERLDLL,$(CFLAGS_O)) $(OBJOUT_FLAG)$@ -c perlmain.c

perlmainst.c : runperl.c
	copy runperl.c perlmainst.c

perlmainst$(o) : perlmainst.c
	$(CC) $(CFLAGS_O) $(OBJOUT_FLAG)$@ -c perlmainst.c

$(PERLEXE): $(PERLDLL) $(CONFIGPM) $(PERLEXE_OBJ) $(PERLEXE_RES)
	$(LINK32) -mconsole -o $@ $(BLINK_FLAGS)  \
	    $(PERLEXE_OBJ) $(PERLEXE_RES) $(PERLIMPLIB) $(LIBFILES)
	copy $(PERLEXE) $(WPERLEXE)
	$(MINIPERL) -I..\lib bin\exetype.pl $(WPERLEXE) WINDOWS

$(PERLEXESTATIC): $(PERLSTATICLIB) $(CONFIGPM) $(PERLEXEST_OBJ) $(PERLEXE_RES)
	$(LINK32) -mconsole -o $@ $(BLINK_FLAGS) \
	    $(PERLEXEST_OBJ) $(PERLEXE_RES) $(PERLSTATICLIB) $(LIBFILES)

MakePPPort: $(MINIPERL) $(CONFIGPM) Extensions_nonxs
	$(MINIPERL) -I..\lib ..\mkppport

#-------------------------------------------------------------------------------
# There's no direct way to mark a dependency on
# DynaLoader.pm, so this will have to do
Extensions : ..\make_ext.pl ..\lib\buildcustomize.pl $(PERLDEP) $(CONFIGPM) $(DYNALOADER)
	$(XCOPY) "..\*.h" $(COREDIR)\$(NULL)
	$(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(CPANDIR) --dir=$(DISTDIR) --dir=$(EXTDIR) --dynamic

Extensions_reonly : ..\make_ext.pl ..\lib\buildcustomize.pl $(PERLDEP) $(CONFIGPM) $(DYNALOADER)
	$(XCOPY) "..\*.h" $(COREDIR)\$(NULL)
	$(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(CPANDIR) --dir=$(DISTDIR) --dir=$(EXTDIR) --dynamic +re

Extensions_static : ..\make_ext.pl ..\lib\buildcustomize.pl list_static_libs.pl $(PERLDEP) $(CONFIGPM) Extensions_nonxs
	$(XCOPY) "..\*.h" $(COREDIR)\$(NULL)
	$(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(CPANDIR) --dir=$(DISTDIR) --dir=$(EXTDIR) --static
	$(MINIPERL) -I..\lib list_static_libs.pl > Extensions_static

Extensions_nonxs : ..\make_ext.pl ..\lib\buildcustomize.pl $(PERLDEP) $(CONFIGPM) ..\pod\perlfunc.pod
	$(XCOPY) "..\*.h" $(COREDIR)\$(NULL)
	$(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(CPANDIR) --dir=$(DISTDIR) --dir=$(EXTDIR) --nonxs

$(DYNALOADER) : ..\make_ext.pl ..\lib\buildcustomize.pl $(PERLDEP) $(CONFIGPM) Extensions_nonxs
	$(XCOPY) "..\*.h" $(COREDIR)\$(NULL)
	$(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(EXTDIR) --dynaloader

Extensions_clean :
	-if exist $(MINIPERL) $(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(CPANDIR) --dir=$(DISTDIR) --dir=$(EXTDIR) --all --target=clean

Extensions_realclean :
	-if exist $(MINIPERL) $(MINIPERL) -I..\lib ..\make_ext.pl "MAKE=$(MAKE)" --dir=$(CPANDIR) --dir=$(DISTDIR) --dir=$(EXTDIR) --all --target=realclean

#-------------------------------------------------------------------------------

doc: $(PERLEXE) ..\pod\perltoc.pod
	$(PERLEXE) -I..\lib ..\installhtml --podroot=.. --htmldir=$(HTMLDIR) \
	    --podpath=pod:lib:utils --htmlroot="file://$(subst :,|,$(INST_HTML))"\
	    --recurse

..\utils\Makefile: $(CONFIGPM) ..\utils\Makefile.PL
	$(MINIPERL) -I..\lib ..\utils\Makefile.PL ..

# Note that this next section is parsed (and regenerated) by pod/buildtoc
# so please check that script before making structural changes here
utils: $(PERLEXE) ..\utils\Makefile
	cd ..\utils && $(MAKE) PERL=$(MINIPERL)
	copy ..\README.aix      ..\pod\perlaix.pod
	copy ..\README.amiga    ..\pod\perlamiga.pod
	copy ..\README.android  ..\pod\perlandroid.pod
	copy ..\README.bs2000   ..\pod\perlbs2000.pod
	copy ..\README.ce       ..\pod\perlce.pod
	copy ..\README.cn       ..\pod\perlcn.pod
	copy ..\README.cygwin   ..\pod\perlcygwin.pod
	copy ..\README.dos      ..\pod\perldos.pod
	copy ..\README.freebsd  ..\pod\perlfreebsd.pod
	copy ..\README.haiku    ..\pod\perlhaiku.pod
	copy ..\README.hpux     ..\pod\perlhpux.pod
	copy ..\README.hurd     ..\pod\perlhurd.pod
	copy ..\README.irix     ..\pod\perlirix.pod
	copy ..\README.jp       ..\pod\perljp.pod
	copy ..\README.ko       ..\pod\perlko.pod
	copy ..\README.linux    ..\pod\perllinux.pod
	copy ..\README.macos    ..\pod\perlmacos.pod
	copy ..\README.macosx   ..\pod\perlmacosx.pod
	copy ..\README.netware  ..\pod\perlnetware.pod
	copy ..\README.openbsd  ..\pod\perlopenbsd.pod
	copy ..\README.os2      ..\pod\perlos2.pod
	copy ..\README.os390    ..\pod\perlos390.pod
	copy ..\README.os400    ..\pod\perlos400.pod
	copy ..\README.plan9    ..\pod\perlplan9.pod
	copy ..\README.qnx      ..\pod\perlqnx.pod
	copy ..\README.riscos   ..\pod\perlriscos.pod
	copy ..\README.solaris  ..\pod\perlsolaris.pod
	copy ..\README.symbian  ..\pod\perlsymbian.pod
	copy ..\README.synology ..\pod\perlsynology.pod
	copy ..\README.tru64    ..\pod\perltru64.pod
	copy ..\README.tw       ..\pod\perltw.pod
	copy ..\README.vos      ..\pod\perlvos.pod
	copy ..\README.win32    ..\pod\perlwin32.pod
	copy ..\pod\perldelta.pod ..\pod\perl5238delta.pod
	$(PERLEXE) $(PL2BAT) $(UTILS)
	$(MINIPERL) -I..\lib ..\autodoc.pl ..
	$(MINIPERL) -I..\lib ..\pod\perlmodlib.PL -q ..

..\pod\perltoc.pod: $(PERLEXE) Extensions Extensions_nonxs
	$(PERLEXE) -f ..\pod\buildtoc -q

# Note that the pod cleanup in this next section is parsed (and regenerated
# by pod/buildtoc so please check that script before making changes here

distclean: realclean
	-del /f $(MINIPERL) $(PERLEXE) $(PERLDLL) $(GLOBEXE) \
		$(PERLIMPLIB) ..\miniperl$(a) $(PERLEXESTATIC) $(PERLSTATICLIB)
	-del /f $(LIBDIR)\Encode.pm $(LIBDIR)\encoding.pm $(LIBDIR)\Errno.pm
	-del /f $(LIBDIR)\Config.pod $(LIBDIR)\POSIX.pod $(LIBDIR)\threads.pm
	-del /f $(LIBDIR)\.exists $(LIBDIR)\attributes.pm $(LIBDIR)\DynaLoader.pm
	-del /f $(LIBDIR)\Fcntl.pm $(LIBDIR)\IO.pm $(LIBDIR)\Opcode.pm
	-del /f $(LIBDIR)\ops.pm $(LIBDIR)\Safe.pm
	-del /f $(LIBDIR)\SDBM_File.pm $(LIBDIR)\Socket.pm $(LIBDIR)\POSIX.pm
	-del /f $(LIBDIR)\B.pm $(LIBDIR)\O.pm $(LIBDIR)\re.pm
	-del /f $(LIBDIR)\File\Glob.pm
	-del /f $(LIBDIR)\Storable.pm
	-del /f $(LIBDIR)\Sys\Hostname.pm
	-del /f $(LIBDIR)\Time\HiRes.pm
	-del /f $(LIBDIR)\Unicode\Normalize.pm
	-del /f $(LIBDIR)\Math\BigInt\FastCalc.pm
	-del /f $(LIBDIR)\Win32.pm
	-del /f $(LIBDIR)\Win32CORE.pm
	-del /f $(LIBDIR)\Win32API\File.pm
	-del /f $(LIBDIR)\Win32API\File\cFile.pc
	-del /f $(LIBDIR)\buildcustomize.pl
	-del /f $(DISTDIR)\XSLoader\XSLoader.pm
	-del /f *.def *.map
	-if exist $(LIBDIR)\App rmdir /s /q $(LIBDIR)\App
	-if exist $(LIBDIR)\Archive rmdir /s /q $(LIBDIR)\Archive
	-if exist $(LIBDIR)\Attribute rmdir /s /q $(LIBDIR)\Attribute
	-if exist $(LIBDIR)\autodie rmdir /s /q $(LIBDIR)\autodie
	-if exist $(LIBDIR)\Carp rmdir /s /q $(LIBDIR)\Carp
	-if exist $(LIBDIR)\Compress rmdir /s /q $(LIBDIR)\Compress
	-if exist $(LIBDIR)\Config\Perl rmdir /s /q $(LIBDIR)\Config\Perl
	-if exist $(LIBDIR)\CPAN rmdir /s /q $(LIBDIR)\CPAN
	-if exist $(LIBDIR)\Data rmdir /s /q $(LIBDIR)\Data
	-if exist $(LIBDIR)\Devel rmdir /s /q $(LIBDIR)\Devel
	-if exist $(LIBDIR)\Digest rmdir /s /q $(LIBDIR)\Digest
	-if exist $(LIBDIR)\Encode rmdir /s /q $(LIBDIR)\Encode
	-if exist $(LIBDIR)\encoding rmdir /s /q $(LIBDIR)\encoding
	-if exist $(LIBDIR)\Exporter rmdir /s /q $(LIBDIR)\Exporter
	-if exist $(LIBDIR)\ExtUtils\CBuilder rmdir /s /q $(LIBDIR)\ExtUtils\CBuilder
	-if exist $(LIBDIR)\ExtUtils\Command rmdir /s /q $(LIBDIR)\ExtUtils\Command
	-if exist $(LIBDIR)\ExtUtils\Constant rmdir /s /q $(LIBDIR)\ExtUtils\Constant
	-if exist $(LIBDIR)\ExtUtils\Liblist rmdir /s /q $(LIBDIR)\ExtUtils\Liblist
	-if exist $(LIBDIR)\ExtUtils\MakeMaker rmdir /s /q $(LIBDIR)\ExtUtils\MakeMaker
	-if exist $(LIBDIR)\ExtUtils\ParseXS rmdir /s /q $(LIBDIR)\ExtUtils\ParseXS
	-if exist $(LIBDIR)\ExtUtils\Typemaps rmdir /s /q $(LIBDIR)\ExtUtils\Typemaps
	-if exist $(LIBDIR)\File\Spec rmdir /s /q $(LIBDIR)\File\Spec
	-if exist $(LIBDIR)\Filter rmdir /s /q $(LIBDIR)\Filter
	-if exist $(LIBDIR)\Hash rmdir /s /q $(LIBDIR)\Hash
	-if exist $(LIBDIR)\HTTP rmdir /s /q $(LIBDIR)\HTTP
	-if exist $(LIBDIR)\I18N rmdir /s /q $(LIBDIR)\I18N
	-if exist $(LIBDIR)\IO rmdir /s /q $(LIBDIR)\IO
	-if exist $(LIBDIR)\IPC rmdir /s /q $(LIBDIR)\IPC
	-if exist $(LIBDIR)\JSON rmdir /s /q $(LIBDIR)\JSON
	-if exist $(LIBDIR)\List rmdir /s /q $(LIBDIR)\List
	-if exist $(LIBDIR)\Locale rmdir /s /q $(LIBDIR)\Locale
	-if exist $(LIBDIR)\Math rmdir /s /q $(LIBDIR)\Math
	-if exist $(LIBDIR)\Memoize rmdir /s /q $(LIBDIR)\Memoize
	-if exist $(LIBDIR)\MIME rmdir /s /q $(LIBDIR)\MIME
	-if exist $(LIBDIR)\Module rmdir /s /q $(LIBDIR)\Module
	-if exist $(LIBDIR)\Net\FTP rmdir /s /q $(LIBDIR)\Net\FTP
	-if exist $(LIBDIR)\Params rmdir /s /q $(LIBDIR)\Params
	-if exist $(LIBDIR)\Parse rmdir /s /q $(LIBDIR)\Parse
	-if exist $(LIBDIR)\Perl rmdir /s /q $(LIBDIR)\Perl
	-if exist $(LIBDIR)\PerlIO rmdir /s /q $(LIBDIR)\PerlIO
	-if exist $(LIBDIR)\Pod\Perldoc rmdir /s /q $(LIBDIR)\Pod\Perldoc
	-if exist $(LIBDIR)\Pod\Simple rmdir /s /q $(LIBDIR)\Pod\Simple
	-if exist $(LIBDIR)\Pod\Text rmdir /s /q $(LIBDIR)\Pod\Text
	-if exist $(LIBDIR)\Scalar rmdir /s /q $(LIBDIR)\Scalar
	-if exist $(LIBDIR)\Search rmdir /s /q $(LIBDIR)\Search
	-if exist $(LIBDIR)\Sub rmdir /s /q $(LIBDIR)\Sub
	-if exist $(LIBDIR)\Sys rmdir /s /q $(LIBDIR)\Sys
	-if exist $(LIBDIR)\TAP rmdir /s /q $(LIBDIR)\TAP
	-if exist $(LIBDIR)\Term rmdir /s /q $(LIBDIR)\Term
	-if exist $(LIBDIR)\Test rmdir /s /q $(LIBDIR)\Test
	-if exist $(LIBDIR)\Text rmdir /s /q $(LIBDIR)\Text
	-if exist $(LIBDIR)\Thread rmdir /s /q $(LIBDIR)\Thread
	-if exist $(LIBDIR)\threads rmdir /s /q $(LIBDIR)\threads
	-if exist $(LIBDIR)\Tie\Hash rmdir /s /q $(LIBDIR)\Tie\Hash
	-if exist $(LIBDIR)\Unicode\Collate rmdir /s /q $(LIBDIR)\Unicode\Collate
	-if exist $(LIBDIR)\Unicode\Collate\Locale rmdir /s /q $(LIBDIR)\Unicode\Collate\Locale
	-if exist $(LIBDIR)\version rmdir /s /q $(LIBDIR)\version
	-if exist $(LIBDIR)\VMS rmdir /s /q $(LIBDIR)\VMS
	-if exist $(LIBDIR)\Win32API rmdir /s /q $(LIBDIR)\Win32API
	-if exist $(LIBDIR)\XS rmdir /s /q $(LIBDIR)\XS
	-cd $(PODDIR) && del /f *.html *.bat roffitall \
	    perl5238delta.pod perlaix.pod perlamiga.pod perlandroid.pod \
	    perlapi.pod perlbs2000.pod perlce.pod perlcn.pod perlcygwin.pod \
	    perldos.pod perlfreebsd.pod perlhaiku.pod perlhpux.pod \
	    perlhurd.pod perlintern.pod perlirix.pod perljp.pod perlko.pod \
	    perllinux.pod perlmacos.pod perlmacosx.pod perlmodlib.pod \
	    perlnetware.pod perlopenbsd.pod perlos2.pod perlos390.pod \
	    perlos400.pod perlplan9.pod perlqnx.pod perlriscos.pod \
	    perlsolaris.pod perlsymbian.pod perlsynology.pod perltoc.pod \
	    perltru64.pod perltw.pod perluniprops.pod perlvos.pod \
	    perlwin32.pod
	-cd ..\utils && del /f h2ph splain perlbug pl2pm c2ph pstruct h2xs \
	    perldoc perlivp libnetcfg enc2xs piconv cpan *.bat \
	    xsubpp pod2html instmodsh json_pp prove ptar ptardiff ptargrep shasum corelist zipdetails
	-del /f ..\config.sh perlmain.c dlutils.c config.h.new \
	    perlmainst.c
	-del /f $(CONFIGPM)
	-del /f ..\lib\Config_git.pl
	-del /f "bin\*.bat"
	-del /f perllibst.h
	-del /f $(PERLEXE_RES) perl.base
	-cd .. && del /s *$(a) *.map *.pdb *.ilk *.bs *$(o) .exists pm_to_blib ppport.h
	-cd $(EXTDIR) && del /s *.def Makefile Makefile.old
	-cd $(DISTDIR) && del /s *.def Makefile Makefile.old
	-cd $(CPANDIR) && del /s *.def Makefile Makefile.old
	-del /s ..\utils\Makefile
	-if exist $(AUTODIR) rmdir /s /q $(AUTODIR)
	-if exist $(COREDIR) rmdir /s /q $(COREDIR)
	-if exist pod2htmd.tmp del pod2htmd.tmp
	-if exist $(HTMLDIR) rmdir /s /q $(HTMLDIR)
	-del /f ..\t\test_state

install : all installbare installhtml

installbare : utils ..\pod\perltoc.pod
	$(PERLEXE) ..\installperl
	if exist $(WPERLEXE) $(XCOPY) $(WPERLEXE) $(INST_BIN)\$(NULL)
	if exist $(PERLEXESTATIC) $(XCOPY) $(PERLEXESTATIC) $(INST_BIN)\$(NULL)
	$(XCOPY) $(GLOBEXE) $(INST_BIN)\$(NULL)
	if exist ..\perl*.pdb $(XCOPY) ..\perl*.pdb $(INST_BIN)\$(NULL)
	$(XCOPY) "bin\*.bat" $(INST_SCRIPT)\$(NULL)

installhtml : doc
	$(RCOPY) $(HTMLDIR)\*.* $(INST_HTML)\$(NULL)

inst_lib : $(CONFIGPM)
	$(RCOPY) ..\lib $(INST_LIB)\$(NULL)

$(UNIDATAFILES) ..\pod\perluniprops.pod .UPDATEALL : $(MINIPERL) $(CONFIGPM) ..\lib\unicore\mktables Extensions_nonxs
	cd ..\lib\unicore && \
	..\$(MINIPERL) -I.. -I..\..\dist\Cwd\lib -I..\..\dist\Cwd mktables -P ..\..\pod -maketest -makelist -p

minitest : $(MINIPERL) $(GLOBEXE) $(CONFIGPM) $(UNIDATAFILES) utils
	$(XCOPY) $(MINIPERL) ..\t\$(NULL)
	if exist ..\t\perl.exe del /f ..\t\perl.exe
	rename ..\t\miniperl.exe perl.exe
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
	attrib -r "..\t\*.*"
	cd ..\t && \
	$(MINIPERL) -I..\lib harness base/*.t comp/*.t cmd/*.t io/*.t opbasic/*.t op/*.t pragma/*.t

test-prep : all utils ..\pod\perltoc.pod
	$(XCOPY) $(PERLEXE) ..\t\$(NULL)
	$(XCOPY) $(PERLDLL) ..\t\$(NULL)
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
# If building with gcc versions 4.x.x or greater, then
# the GCC helper DLL will also need copied to the test directory.
# The name of the dll can change, depending upon which vendor has supplied
# your compiler, and upon the values of "x".
# libstdc++-6.dll is copied if it exists as it, too, may then be needed.
# Without this copying, the op/taint.t test script will fail.
	if exist $(CCDLLDIR)\libgcc_s_seh-1.dll $(XCOPY) $(CCDLLDIR)\libgcc_s_seh-1.dll ..\t\$(NULL)
	if exist $(CCDLLDIR)\libgcc_s_sjlj-1.dll $(XCOPY) $(CCDLLDIR)\libgcc_s_sjlj-1.dll ..\t\$(NULL)
	if exist $(CCDLLDIR)\libgcc_s_dw2-1.dll $(XCOPY) $(CCDLLDIR)\libgcc_s_dw2-1.dll ..\t\$(NULL)
	if exist $(CCDLLDIR)\libstdc++-6.dll $(XCOPY) $(CCDLLDIR)\libstdc++-6.dll ..\t\$(NULL)
	if exist $(CCDLLDIR)\libwinpthread-1.dll $(XCOPY) $(CCDLLDIR)\libwinpthread-1.dll ..\t\$(NULL)

test : test-prep
	set PERL_STATIC_EXT=$(STATIC_EXT) && \
	    cd ..\t && $(PERLEXE) -I..\lib harness $(TEST_SWITCHES) $(TEST_FILES)

test_porting : test-prep
	set PERL_STATIC_EXT=$(STATIC_EXT) && \
	    cd ..\t && $(PERLEXE) -I..\lib harness $(TEST_SWITCHES) porting\*.t ..\lib\diagnostics.t

test-reonly : reonly utils
	$(XCOPY) $(PERLEXE) ..\t\$(NULL)
	$(XCOPY) $(PERLDLL) ..\t\$(NULL)
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
	cd ..\t && \
	$(PERLEXE) -I..\lib harness $(OPT) -re \bpat\\/ $(EXTRA) && \
	cd ..\win32

regen :
	cd .. && regen.pl && cd win32

test-notty : test-prep
	set PERL_STATIC_EXT=$(STATIC_EXT) && \
	    set PERL_SKIP_TTY_TEST=1 && \
	    cd ..\t && $(PERLEXE) -I.\lib harness $(TEST_SWITCHES) $(TEST_FILES)

_test :
	$(XCOPY) $(PERLEXE) ..\t\$(NULL)
	$(XCOPY) $(PERLDLL) ..\t\$(NULL)
	$(XCOPY) $(GLOBEXE) ..\t\$(NULL)
	set PERL_STATIC_EXT=$(STATIC_EXT) && \
	    cd ..\t && $(PERLEXE) -I..\lib harness $(TEST_SWITCHES) $(TEST_FILES)

_clean :
	-@erase miniperlmain$(o)
	-@erase $(MINIPERL)
	-@erase perlglob$(o)
	-@erase perlmain$(o)
	-@erase perlmainst$(o)
	-@erase /f config.h
	-@erase /f ..\git_version.h
	-@erase $(GLOBEXE)
	-@erase $(PERLEXE)
	-@erase $(WPERLEXE)
	-@erase $(PERLEXESTATIC)
	-@erase $(PERLSTATICLIB)
	-@erase $(PERLDLL)
	-@erase $(CORE_OBJ)
	-@erase $(GENUUDMAP) $(GENUUDMAP_OBJ) $(GENERATED_HEADERS)
	-if exist $(MINIDIR) rmdir /s /q $(MINIDIR)
	-if exist $(UNIDATADIR1) rmdir /s /q $(UNIDATADIR1)
	-if exist $(UNIDATADIR2) rmdir /s /q $(UNIDATADIR2)
	-@erase $(UNIDATAFILES)
	-@erase $(WIN32_OBJ)
	-@erase $(DLL_OBJ)
	-@erase ..\*$(o) ..\*$(a) ..\*.exp *$(o) *$(a) *.exp *.res
	-@erase ..\t\*.exe ..\t\*.dll ..\t\*.bat
	-@erase *.ilk
	-@erase *.pdb
	-@erase Extensions_static

clean : Extensions_clean _clean

realclean : Extensions_realclean _clean

# Handy way to run perlbug -ok without having to install and run the
# installed perlbug. We don't re-run the tests here - we trust the user.
# Please *don't* use this unless all tests pass.
# If you want to report test failures, use "gmake nok" instead.
ok: utils
	$(PERLEXE) -I..\lib ..\utils\perlbug -ok -s "(UNINSTALLED)"

okfile: utils
	$(PERLEXE) -I..\lib ..\utils\perlbug -ok -s "(UNINSTALLED)" -F perl.ok

nok: utils
	$(PERLEXE) -I..\lib ..\utils\perlbug -nok -s "(UNINSTALLED)"

nokfile: utils
	$(PERLEXE) -I..\lib ..\utils\perlbug -nok -s "(UNINSTALLED)" -F perl.nok
