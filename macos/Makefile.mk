#######################################################################
#	Project		:	Perl 5
#	File		:	Makefile			-	Build everything except examples
#	Author		:	Matthias Neeracher
#	Language	:	MPW Shell/Make
#

MACPERL_SRC	= {$(PWD)}:

.INCLUDE : $(MACPERL_SRC)BuildRules.mk

DB		= :::db:
XL		= :::XL:
GD		= :ext:GD:libgd:
AEGizmos	= :::AEGizmos:
IC 		= :::IC:
SFIO		= "{{SFIO}}"
GUSI		= "{{GUSI}}"
MoreFiles	= :::MoreFiles:

.SOURCE.c	: "$(MoreFiles)Sources:"

# Add -d LEAKTEST -d DUMPADDR -d MALLOC_LOG as you see fit
LeakOpt		=	-d LEAKTEST -d DEBUGGING

COpt		+= -d PERL_CORE
CInc		+= -i "$(MoreFiles)CHeaders:"

YACC = yacc

LibFiles68K	=	:PLib:PerlLib.68K.Lib					\
			"$(GUSI)lib:GUSI_Forward.68K.Lib"					\
			"{{MW68KLibraries}}MSL MPWRuntime.68K.Lib"		\
			"{{MW68KLibraries}}MSL Runtime68K.Lib"			\
			"$(GUSI)lib:GUSI_MPW.68K.Lib"					\
			"{{Libraries}}IntEnv.o"							\
			"{{Libraries}}ToolLibs.o"						\
			"{{MW68KLibraries}}MacOS.Lib"					\
			"{{MW68KLibraries}}MSL C.68K MPW(NL_4i_8d).Lib"	\
			"{{MW68KLibraries}}MSL C++.68K (4i_8d).Lib"		\
			"{{MW68KLibraries}}MathLib68K (4i_8d).Lib"		\
			$(SFIO)lib:sfio.68K.Lib							\
			"{{Libraries}}OpenTransportApp.o"				\
			"{{Libraries}}OpenTransport.o"					\
			"{{Libraries}}OpenTptInet.o"					\
			"$(GUSI)lib:GUSI_Sfio.68K.Lib"					\
			"$(GUSI)lib:GUSI_Core.68K.Lib"
MoLibs68K	=	"$(DB)lib:db.Sfio.68K.Lib"			\
			"$(XL)"XL.68K.Lib				\
			"{{Libraries}}OSACompLib.o"
BigLibs68K	=	:Obj:CheckIsRecord.c.68K.o "$(AEGizmos)AEGizmos4Perl.Lib.68K"	\
			"$(GD)libgd.Lib.68K"				\
			"{{MW68KLibraries}}QTVR.MW.c.o"	\
			"$(IC)ICGlueFar.o"		

LibFilesPPC	=	\
			"$(GUSI)lib:GUSI_MPW.PPC.Lib"					\
			"$(GUSI)lib:GUSI_Sfio.PPC.Lib"					\
			:PLib:PerlLib.PPC.Lib							\
			"$(GUSI)lib:GUSI_Core.PPC.Lib"					\
			"{{MWPPCLibraries}}MSL MPWCRuntime.Lib"			\
			"{{SharedLibraries}}InterfaceLib"				\
			$(SFIO)lib:sfio.PPC.Lib							\
			"{{MWPPCLibraries}}MSL C.PPC MPW(NL).Lib"		\
			"{{MWPPCLibraries}}MSL C++.PPC (NL).Lib"		\
			"{{SharedLibraries}}StdCLib"					\
			"{{SharedLibraries}}MathLib"					\
			"{{SharedLIbraries}}ThreadsLib"					\
			"{{SharedLibraries}}OpenTransportLib"			\
			"{{SharedLibraries}}OpenTptInternetLib"			\
			"{{PPCLibraries}}OpenTransportAppPPC.o"			\
			"{{PPCLibraries}}OpenTptInetPPC.o"				\
			"{{PPCLibraries}}PPCToolLibs.o"
MoLibsPPC	=	"$(DB)lib:db.Sfio.PPC.Lib"				\
			"$(XL)"XL.PPC.Lib				\
			"{{SharedLibraries}}AppleScriptLib"

LibFilesSC	=	\
			"$(GUSI)lib:GUSI_MPW.SC.Lib"					\
			"$(GUSI)lib:GUSI_Sfio.SC.Lib"					\
			:PLib:PerlLib.SC.Lib							\
			"$(GUSI)lib:GUSI_Core.SC.Lib"					\
			"$(SFIO)lib:sfio.SC.Lib"						\
			"{{CLibraries}}CPlusLib.far.o"					\
			"{{CLibraries}}StdCLib.far.o"					\
			"{{Libraries}}MacRuntime.o"						\
			"{{Libraries}}Interface.o"						\
			"{{Libraries}}IntEnv.far.o"						\
			"{{Libraries}}MathLib.far.o"					\
			"{{Libraries}}ToolLibs.far.o"					\
			"{{CLibraries}}IOStreams.far.o"					\
			"{{Libraries}}OpenTransport.o"					\
			"{{Libraries}}OpenTransportApp.o"				\
			"{{Libraries}}OpenTptInet.o"
MoLibsSC	=	"$(DB)lib:db.Sfio.SC.Lib"					\
			"$(XL)"XL.SC.Lib

LibFilesMrC	= 	\
			"$(GUSI)lib:GUSI_MPW.MrC.Lib"					\
			"$(GUSI)lib:GUSI_Sfio.MrC.Lib"					\
			:PLib:PerlLib.MrC.Lib							\
			"$(GUSI)lib:GUSI_Core.MrC.Lib"					\
			"$(SFIO)lib:sfio.MrC.Lib"						\
			"{{PPCLibraries}}MrCPlusLib.o"					\
			"{{PPCLibraries}}PPCStdCLib.o"					\
			"{{PPCLibraries}}StdCRuntime.o"					\
			"{{PPCLibraries}}PPCCRuntime.o"					\
			"{{SharedLibraries}}MathLib"					\
			"{{PPCLibraries}}PPCToolLibs.o"					\
			"{{SharedLibraries}}InterfaceLib"				\
			"{{SharedLibraries}}ThreadsLib"					\
			"{{PPCLibraries}}MrCIOStreams.o"				\
			"{{SharedLibraries}}StdCLib"					\
			"{{SharedLibraries}}OpenTransportLib"			\
			"{{SharedLibraries}}OpenTptInternetLib"			\
			"{{PPCLibraries}}OpenTransportAppPPC.o"			\
			"{{PPCLibraries}}OpenTptInetPPC.o"
MoLibsMrC	=	"$(DB)lib:db.Sfio.MrC.Lib"				\
			"$(XL)"XL.MrC.Lib							\
			"{{SharedLibraries}}AppleScriptLib"

LNS = Perl -e 'symlink($ARGV[0], $ARGV[1])'
RMS = delete -y 

public		=	perl translators sitelib_install 
Dynamic_Ext_Mac	=	Mac
Dynamic_Ext_Std	=	
Dynamic_Ext_Xtr =
# this should be rewritten some, eh?
Static_Lib_Mac	= \
	ExtUtils:MM_MacOS ExtUtils:Miniperl Config Errno \
	Mac:Hooks Mac:Pane Mac:LowMem \
	Mac:AppleEvents:Simple Mac:OSA:Simple \
	Mac:BuildTools Mac:Apps:Launch Mac:Toolbox \
	Mac:AETE:App Mac:AETE:Dialect Mac:AETE:Parser \
	Mac:AETE:Format:Converter Mac:AETE:Format:Dictionary \
	Mac:AETE:Format:Glue Mac:Glue

########
# sync all extensions with both config.sh and macperl/Makefile.mk!
########
Static_Ext_Xtr =	\
	Compress:Zlib:Zlib Digest:MD5:MD5 Filter:Util:Call:Call \
	HTML:Parser:Parser List:Util:Util MIME:Base64:Base64 \
	Storable:Storable Time:HiRes:HiRes
Static_Ext_Mac	= 	\
	MacPerl:MacPerl 
#	Mac:err:err				\
#	Mac:AppleEvents:AppleEvents		\
#	Mac:Components:Components		\
#	Mac:Controls:Controls			\
#	Mac:Dialogs:Dialogs			\
#	Mac:Events:Events			\
#	Mac:Files:Files				\
#	Mac:Fonts:Fonts				\
#	Mac:Gestalt:Gestalt			\
#	Mac:InternetConfig:InternetConfig	\
#	Mac:Lists:Lists				\
#	Mac:Memory:Memory			\
#	Mac:Menus:Menus				\
#	Mac:MoreFiles:MoreFiles			\
#	Mac:Movies:Movies			\
#	Mac:Notification:Notification		\
#	Mac:OSA:OSA				\
#	Mac:Processes:Processes			\
#	Mac:QDOffscreen:QDOffscreen		\
#	Mac:QuickDraw:QuickDraw			\
#	Mac:QuickTimeVR:QuickTimeVR		\
#	Mac:Resources:Resources			\
#	Mac:Sound:Sound				\
#	Mac:Speech:Speech			\
#	Mac:SpeechRecognition:SpeechRecognition	\
#	Mac:StandardFile:StandardFile		\
#	Mac:TextEdit:TextEdit			\
#	Mac:Types:Types				\
#	Mac:Windows:Windows

Static_Ext_Std	= 	\
	B:B ByteLoader:ByteLoader Data:Dumper:Dumper DB_File:DB_File \
	Devel:DProf:DProf Devel:Peek:Peek DynaLoader:DynaLoader \
	Fcntl:Fcntl File:Glob:Glob IO:IO \
	NDBM_File:NDBM_File Opcode:Opcode POSIX:POSIX \
	Socket:Socket Sys:Hostname:Hostname \
 	attrs:attrs re:re
	# Errno:Errno done, in from :macos:lib:
	# not going to be built:
	# GDBM_File:GDBM_File ODBM_File:ODBM_File IPC:IPC:SysV
	# SDBM_File:SDBM_File Sys:Syslog:Syslog Thread:Thread

Static_Ext_AutoInit	= 	$(Static_Ext_Mac) $(Static_Ext_Std) $(Static_Ext_Xtr)
More_Static_Ext		= 	OSA XL
Static_Ext_Prefix	= 	:ext:{$(Static_Ext_Mac)} ::ext:{$(Static_Ext_Std)} :bundled_ext:{$(Static_Ext_Xtr)}
Static_Ext_AutoInit_PPC	=	{$(Static_Ext_Prefix)}.Lib.PPC
Static_Ext_AutoInit_68K	=	{$(Static_Ext_Prefix)}.Lib.68K
Static_Ext_AutoInit_SC	=	{$(Static_Ext_Prefix)}.Lib.SC
Static_Ext_AutoInit_MrC	=	{$(Static_Ext_Prefix)}.Lib.MrC


private = :lib:Config.pm preplibrary :lib:ExtUtils:Miniperl.pm

# Files to be built with variable substitution after miniperl is
# available.  Dependencies handled manually below (for now).

pl = "::pod:pod2html.PL" "::pod:pod2latex.PL" "::pod:pod2man.PL" "::pod:pod2text.PL"

plextract = "::pod:pod2html" "::pod:pod2latex" "::pod:pod2man" "::pod:pod2text"

addedbyconf = UU $(plextract) pstruct

h1 = EXTERN.h INTERN.h XSUB.h av.h config.h cop.h cv.h dosish.h
h2 = embed.h form.h gv.h handy.h hv.h keywords.h mg.h op.h
h3 = opcode.h patchlevel.h perl.h perly.h pp.h proto.h regcomp.h
h4 = regexp.h scope.h sv.h unixish.h util.h
h = $(h1) $(h2) $(h3) $(h4)

c1 = $(mallocsrc) av.c scope.c op.c doop.c doio.c dump.c hv.c mg.c perlapi.c
c2 = perl.c perly.c pp.c pp_hot.c pp_ctl.c pp_sys.c regcomp.c regexec.c xsutils.c
c3 = gv.c sv.c taint.c toke.c util.c deb.c run.c globals.c perlio.c utf8.c universal.c
cm = SubLaunch.c crypt.c
mf = DirectoryCopy.c FileCopy.c FSpCompat.c FullPath.c IterateDirectory.c MoreDesktopMgr.c \
	MoreFiles.c MoreFilesExtras.c Search.c

c = $(c1) $(c2) $(c3) $(cm)
cp= $(cpm)
libc = macish.c icemalloc.c PerlGUSIConfig.cp $(mf)

Objects68K = {$(c)}.68K.o
ObjectsPPC = {$(c)}.PPC.o
ObjectsSC = {$(c)}.SC.o
ObjectsMRC = {$(c)}.MrC.o
ObjectsLeakPPC = {$(c)}.l.PPC.o
LibObjects68K = {$(libc)}.68K.o
LibObjectsPPC = {$(libc)}.PPC.o
LibObjectsSC = {$(libc)}.SC.o
LibObjectsMRC = {$(libc)}.MrC.o

.PHONY : translators sitelib_install

all: PLib Obj xsubppdup miniperl $(private) $(plextract) $(public) dynlibrary runperl extrlibrary
	@echo " "; echo "	Everything is up to date."

PLib: 
	NewFolder PLib

xsubppdup:
	Duplicate -y xsubpp ::lib:ExtUtils:xsubpp

translators:	miniperl :lib:Config.pm
.IF "68K" == "$(MACPERL_INST_TOOL_68K)"
	@echo "	Making x2p stuff"; 
	Directory x2p; 
		set echo 0
		BuildProgram all
		set echo 1
	Directory ::
.END

sitelib_install: 
	Directory :lib:
	$(MACPERL_SRC)InstallBLIB "" ¶
		"::perl -I: -I:::lib: -e 'use File::Path; mkpath(\@ARGV, 1);'" ¶
		$(Static_Lib_Mac:^":":+".pm") $(Static_Lib_Mac:^":":+".pod")
	$(MACPERL_SRC)PerlInstall -l :::lib: 
	Directory ::bundled_lib:
	$(MACPERL_SRC)PerlInstall -l :::lib:
	Directory ::


# This is now done by installman only if you actually want the man pages.
#	@echo " "; echo "	Making docs"; cd pod; $(MAKE) all;

# The $& notation tells Sequent machines that it can do a parallel make,
# and is harmless otherwise.
# The miniperl -w -MExporter line is a basic cheap test to catch errors
# before make goes on to run preplibrary and then MakeMaker on extensions.
# This is very handy because later errors are often caused by miniperl
# build problems but that's not obvious to the novice.
# The Module used here must not depend on Config or any extensions.

.INIT : Obj PLib xsubppdup

miniperl:  miniperl.{$(MACPERL_BUILD_TOOL)}
	FatBuild miniperl $(MACPERL_INST_TOOL_PPC) $(MACPERL_INST_TOOL_68K)
	:miniperl -w -I::lib -MExporter -e 0 || BuildProgram minitest
miniperl.68K:	:PLib:Perl.68K.Lib :PLib:PerlLib.68K.Lib miniperlmain.c.68K.o
	$(Link68K) -o miniperl.68K :Obj:miniperlmain.c.68K.o $(LibFiles68K)  :PLib:Perl.68K.Lib
miniperl.68K::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o miniperl.68K
miniperl.PPC:	:PLib:Perl.PPC.Lib :PLib:PerlLib.PPC.Lib miniperlmain.c.PPC.o
	$(LinkPPC) -o miniperl.PPC :Obj:miniperlmain.c.PPC.o $(LibFilesPPC) :PLib:Perl.PPC.Lib
miniperl.PPC::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o miniperl.PPC
miniperl.SC:	:PLib:Perl.SC.Lib :PLib:PerlLib.SC.Lib miniperlmain.c.SC.o
	$(LinkSC) -o miniperl.SC :Obj:miniperlmain.c.SC.o $(LibFilesSC) :PLib:Perl.SC.Lib
miniperl.SC::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o miniperl.SC
miniperl.MrC:	:PLib:Perl.MrC.Lib :PLib:PerlLib.MrC.Lib miniperlmain.c.MrC.o
	$(LinkMrC) -o miniperl.MrC :Obj:miniperlmain.c.MrC.o $(LibFilesMrC) :PLib:Perl.MrC.Lib
miniperl.MrC::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o miniperl.MrC

perlmain.c: miniperl miniperlmain.c Makefile.mk
	miniperl writemain $(Static_Ext_AutoInit) $(More_Static_Ext) > perlmain.c
bigperlmain.c: miniperl miniperlmain.c Makefile.mk
	miniperl writemain $(Big_Static_Ext_AutoInit) $(More_Static_Ext) > bigperlmain.c
runperl.c: miniperl miniperlmain.c Makefile.mk
	miniperl writemain -runperl $(Static_Ext_AutoInit) $(More_Static_Ext) > runperl.c
leakperl.c: miniperl miniperlmain.c Makefile.mk
	miniperl writemain -leakperl > leakperl.c

runperl: runperl.c 
#
# Library building is rather time consuming for make, so we set preplibrary
# to prevent further builds until it is deleted.
#
preplibrary: miniperl
	For i in :bundled_ext:{$(Static_Ext_Xtr:d)} :ext:{$(Static_Ext_Mac:d)} ::ext:{$(Static_Ext_Std:d)}
		directory {{i}}
		Set Echo 0
		If `Newer Makefile.PL Makefile.mk` == "Makefile.PL"
			$(MACPERL_SRC)miniperl -I$(MACPERL_SRC)lib -I$(MACPERL_SRC):lib Makefile.PL
		End
		BuildProgram static
		BuildProgram install_static
		directory $(MACPERL_SRC)
		Set Echo 1
	end
	:miniperl -Ilib -I::lib -e 'use AutoSplit; autosplit_lib_modules(@ARGV)' :lib:Å.pm :lib:Å:Å.pm
	directory ::
	:macos:miniperl -Ilib -I:macos:lib -e 'use AutoSplit; autosplit_lib_modules(@ARGV)' :lib:Å.pm :lib:Å:Å.pm
	directory macos
	Echo > preplibrary

dynlibrary: perl PerlStub
	For i in :bundled_ext:{$(Dynamic_Ext_Xtr)} ::ext:{$(Dynamic_Ext_Std)} :ext:{$(Dynamic_Ext_Mac)}
		directory {{i}}
		Set Echo 0
		If `Exists Makefile.PL` != ""
			If `Newer Makefile.PL Makefile.mk` == "Makefile.PL"
				$(MACPERL_SRC)perl -I$(MACPERL_SRC)lib -I$(MACPERL_SRC):lib Makefile.PL
			End
		End
		BuildProgram all
		BuildProgram install
		directory $(MACPERL_SRC)
		Set Echo 1
	end
	Echo > dynlibrary

extrlibrary: dynlibrary
	For i in :bundled_ext:{$(Dynamic_Ext_Xtr)}
		directory {{i}}
		Set Echo 0
		If `Exists Makefile.PL` != ""
			If `Newer Makefile.PL Makefile.mk` == "Makefile.PL"
				$(MACPERL_SRC)perl -I$(MACPERL_SRC)lib -I$(MACPERL_SRC):lib Makefile.PL
			End
		End
		BuildProgram all
		BuildProgram install
		directory $(MACPERL_SRC)
		Set Echo 1
	end
	Echo > extrlibrary

perl: perl.{$(MACPERL_BUILD_TOOL)}
	FatBuild perl $(MACPERL_INST_TOOL_PPC) $(MACPERL_INST_TOOL_68K)
perl.68K:	:PLib:Perl.68K.Lib :PLib:PerlLib.68K.Lib perlmain.c.68K.o preplibrary
	$(Link68K) -o perl.68K ¶
		:Obj:perlmain.c.68K.o $(LibFiles68K) :Obj:{$(LibObjects68K)} ¶
		:PLib:Perl.68K.Lib $(Static_Ext_AutoInit_68K) $(MoLibs68K) 
perl.68K::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o perl.68K
perl.PPC:	:PLib:Perl.PPC.Lib :PLib:PerlLib.PPC.Lib perlmain.c.PPC.o preplibrary perl.exp
	$(LinkPPC) -map perl.map -@export perl.exp -name Perl -o perl.PPC ¶
		:Obj:perlmain.c.PPC.o $(LibFilesPPC) ¶
		:PLib:Perl.PPC.Lib $(Static_Ext_AutoInit_PPC) $(MoLibsPPC)
perl.PPC::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o perl.PPC
perl.SC:	:PLib:Perl.SC.Lib :PLib:PerlLib.SC.Lib perlmain.c.SC.o preplibrary
	$(LinkSC) -o perl.SC ¶
		:Obj:perlmain.c.SC.o $(LibFilesSC) :Obj:{$(LibObjectsSC)} ¶
		:PLib:Perl.SC.Lib $(Static_Ext_AutoInit_SC) $(MoLibsSC) 
perl.SC::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o perl.SC
perl.MrC:	:PLib:Perl.MrC.Lib :PLib:PerlLib.MrC.Lib perlmain.c.MrC.o preplibrary perl.exp
	$(LinkMrC) -@export perl.exp -fragname Perl -o perl.MrC ¶
		:Obj:perlmain.c.MrC.o $(LibFilesMrC) ¶
		:PLib:Perl.MrC.Lib $(Static_Ext_AutoInit_MrC) $(MoLibsMrC)
perl.MrC::	Perl.r Perl.rsrc 
	Rez $(ROptions) -a -c 'MPS ' -t MPST Perl.r -o perl.MrC

PerlStub:	perl.exp
	MakeStub -d perl.exp -o PerlStub -arch fat -fragname Perl -p

perl.exp: miniperl ::makedef.pl perl.nosym ::global.sym ::pp.sym ::globvar.sym macperl.sym
	:miniperl ::makedef.pl PLATFORM=MacOS | sort -unique> perl.exp

# Take care to avoid modifying lib/Config.pm without reason
":lib:Config.pm": miniperl ":lib:re.pm"
	:miniperl -I::lib: configpm

":lib:ExtUtils:Miniperl.pm": miniperlmain.c miniperl "::minimod.pl" ":lib:Config.pm"
	:miniperl ::minimod.pl > :lib:ExtUtils:Miniperl.pm

":lib:re.pm": "::ext:re:re.pm"
	Duplicate -y $< $@

$(plextract):	miniperl ":lib:Config.pm"
	:miniperl -Ilib -I::lib $@.PL

install: all install.perl install.man

install.perl:	all installperl
	:perl installperl

install.man:	all installman
	:perl installman

# Not implemented yet.
#install.html:	all installhtml
#	./perl installhtml

# I now supply perly.c with the kits, so the following section is
# used only if you force byacc to run by saying
# 	make run_byacc
# Since we patch up the byacc output, the perly.fixer script needs
# to run with precisely the same version of byacc as I use.  You
# normally shouldn't remake perly.[ch].

run_byacc:
	@ echo 'Expect' 130 shift/reduce and 1 reduce/reduce conflict
	$(YACC) -d perly.y
	sh $(shellflags) ./perly.fixer y.tab.c perly.c
	mv y.tab.h perly.h
	echo 'extern YYSTYPE yylval;' >>perly.h
	- perl vms/vms_yfix.pl perly.c perly.h vms/perly_c.vms vms/perly_h.vms

# We don't want to regenerate perly.c and perly.h, but they might
# appear out-of-date after a patch is applied or a new distribution is
# made.
perly.c: perly.y
	SetFile -m . $@

perly.h: perly.y
	SetFile -m . $@

# The following three header files are generated automatically
#	keywords.h:	keywords.pl
#	opcode.h:	opcode.pl
#	embed.h:  	embed.pl global.sym interp.sym
# The correct versions should be already supplied with the perl kit,
# in case you don't have perl available.
# To force them to run, type
#	make regen_headers
regen_headers:
	:perl keywords.pl
	:perl opcode.pl
	:perl embed.pl

clean:
	rm -f *$(OBJ_EXT) *$(LIB_EXT) all perlmain.c
	rm -f perl.exp ext.libs
	-rm perl.export perl.dll perl.libexp perl.map perl.def
	-cd pod; $(MAKE) clean
	-cd utils; $(MAKE) clean
	-cd x2p; $(MAKE) clean
	-@for x in $(DYNALOADER) $(dynamic_ext) $(static_ext) ; do \
	sh ext/util/make_ext clean $$x ; \
	done
	rm -f perl suidperl miniperl $(perllib)

realclean: clean
	-cd os2; rm -f Makefile
	-cd pod; $(MAKE) realclean
	-cd utils; $(MAKE) realclean
	-cd x2p; $(MAKE) realclean
	-@for x in $(DYNALOADER) $(dynamic_ext) $(static_ext) ; do \
	sh ext/util/make_ext realclean $$x ; \
	done
	rm -f *.orig */*.orig *~ */*~ core t/core t/c t/perl
	rm -rf $(addedbyconf)
	rm -f $(FIRSTMAKEFILE) $(FIRSTMAKEFILE).old
	rm -f $(private)
	rm -rf lib/auto
	rm -f lib/.exists
	rm -f h2ph.man pstruct
	rm -rf .config
	@echo "Note that make realclean does not delete config.sh"

clobber:	realclean
	rm -f config.sh cppstdin

distclean:	clobber

test: miniperl perl preplibrary $(dynamic_ext)
	- cd t && chmod +x TEST */*.t
	- cd t && (rm -f perl$(EXE_EXT); $(LNS) ../perl$(EXE_EXT) perl$(EXE_EXT)) && ./perl TEST </dev/tty

minitest: miniperl
	- cd t && chmod +x TEST */*.t
	- cd t && (rm -f perl$(EXE_EXT); $(LNS) ../miniperl$(EXE_EXT) perl$(EXE_EXT)) \
		&& ./perl TEST base/*.t comp/*.t cmd/*.t io/*.t op/*.t </dev/tty

":PLib:Perl.68K.Lib"	:	$(Objects68K)
	$(Lib68K) -o :PLib:Perl.68K.Lib :Obj:{$(Objects68K)}	
":PLib:Perl.PPC.Lib"	:	$(ObjectsPPC)
	$(LibPPC) -o :PLib:Perl.PPC.Lib :Obj:{$(ObjectsPPC)}	
":PLib:Perl.SC.Lib"	:	$(ObjectsSC)
	$(LibSC) -o :PLib:Perl.SC.Lib :Obj:{$(ObjectsSC)}
":PLib:Perl.MrC.Lib"	:	$(ObjectsMRC)
	$(LibMrC) -o :PLib:Perl.MrC.Lib :Obj:{$(ObjectsMRC)}

":PLib:PerlLib.68K.Lib"	:	$(LibObjects68K)	
	$(Lib68K) -o :PLib:PerlLib.68K.Lib :Obj:{$(LibObjects68K)}
":PLib:PerlLib.PPC.Lib"	:	$(LibObjectsPPC)	
	$(LibPPC) -o :PLib:PerlLib.PPC.Lib :Obj:{$(LibObjectsPPC)}
":PLib:PerlLib.SC.Lib"	:	$(LibObjectsSC)	
	$(LibSC) -o :PLib:PerlLib.SC.Lib :Obj:{$(LibObjectsSC)}
":PLib:PerlLib.MrC.Lib"	:	$(LibObjectsMRC)	
	$(LibMrC) -o :PLib:PerlLib.MrC.Lib :Obj:{$(LibObjectsMRC)}

macish.c : macish.h
	SetFile -m . macish.c

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk
