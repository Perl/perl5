#######################################################################
# Project	: MacPerl		-
# File		: Makefile.mk	-	dmake Makefile for MacPerl
# Author	: Matthias Neeracher
# Language	: MPW Shell/Make
#

PERL_SRC 	= ::perl:
MACPERL_SRC	= $(PERL_SRC)macos:

.INCLUDE : $(MACPERL_SRC)BuildRules.mk

DB		= $(PERL_SRC):db:
XL		= $(PERL_SRC):XL:
GD		= :perl:macos:ext:GD:libgd:
AEGizmos	= $(PERL_SRC):AEGizmos:
IC 		= $(PERL_SRC):IC:
SFIO		= "{{SFIO}}"
GUSI		= "{{GUSI}}"
MoreFiles	= $(PERL_SRC):MoreFiles:

COpt += -i $(MACPERL_SRC) -i $(PERL_SRC) -i $(DB)include: -i $(IC) -i $(AEGizmos)include:
ApplRez 		= 	Rez -a -t APPL -c McPL -i $(MACPERL_SRC)
ApplMWLOpt		=	${LOpt} -xm application -d -warn
ApplLink68K		=	MWLink68K ${ApplMWLOpt} -model far
ApplLinkPPC		=	MWLinkPPC ${ApplMWLOpt} 
ApplMPWLOpt		=	${LOpt} -t APPL -w -mf 
ApplLinkSC		=	Link ${ApplMPWLOpt}  -model far
ApplLinkMrC		= 	PPCLink ${ApplMPWLOpt}
RsrcLink68K		= 	MWLink68K -xm coderesource
RsrcLinkSC		=	Link

MacPerlSources	=		\
	MPUtils.c		\
	MPAEUtils.c		\
	MPAppleEvents.c		\
	MPGlobals.c		\
	MPEditions.c		\
	MPFile.c		\
	MPMain.c		\
	MPEditor.c		\
	MPWindow.c		\
	MPHelp.c		\
	MPScript.c		\
	MPSave.c		\
	MercutioAPI.c	\
	MPConsole.cp		\
	MPPreferences.c		\
	MPPseudoFile.cp		\
	MPAEVTStream.cp

.SOURCE.c : $(MACPERL_SRC)
.SOURCE.h : $(MACPERL_SRC)

.INIT : Obj "MacPerl Extensions"

PerlSources = runperl.c

Objects68K 		= {$(MacPerlSources) $(PerlSources)}.68K.o
ObjectsPPC 		= {$(MacPerlSources) $(PerlSources)}.PPC.o
ObjectsSC 		= {$(MacPerlSources) $(PerlSources)}.SC.o
ObjectsMrC 		= {$(MacPerlSources) $(PerlSources)}.MrC.o

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
#	Mac:Navigation:Navigation		\
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

Static_Ext_Prefix	= 	$(MACPERL_SRC)ext:{$(Static_Ext_Mac)} $(PERL_SRC)ext:{$(Static_Ext_Std)} $(MACPERL_SRC)bundled_ext:{$(Static_Ext_Xtr)}
Static_Ext_AutoInit_PPC	=	{$(Static_Ext_Prefix)}.Lib.PPC
Static_Ext_AutoInit_68K	=	{$(Static_Ext_Prefix)}.Lib.68K
Static_Ext_AutoInit_SC	=	{$(Static_Ext_Prefix)}.Lib.SC
Static_Ext_AutoInit_MrC	=	{$(Static_Ext_Prefix)}.Lib.MrC

PerlObj68K	=				\
	$(MACPERL_SRC)PLib:PerlLib.68K.Lib		\
	$(MACPERL_SRC)PLib:Perl.68K.Lib		\
	$(Static_Ext_AutoInit_68K)

PerlObjPPC	=				\
	$(MACPERL_SRC)PLib:PerlLib.PPC.Lib		\
	$(MACPERL_SRC)PLib:Perl.PPC.Lib		\
	$(Static_Ext_AutoInit_PPC)

PerlObjSC	=				\
	$(MACPERL_SRC)PLib:PerlLib.SC.Lib		\
	$(MACPERL_SRC)PLib:Perl.SC.Lib		\
	$(Static_Ext_AutoInit_SC)

PerlObjMrC	=				\
	$(MACPERL_SRC)PLib:PerlLib.MrC.Lib		\
	$(MACPERL_SRC)PLib:Perl.MrC.Lib		\
	$(Static_Ext_AutoInit_MrC)

MacPerlLibPPC	=					\
			"$(GUSI)lib:GUSI_Sfio.PPC.Lib"					\
			"$(GUSI)lib:GUSI_Core.PPC.Lib"					\
			"{{MWPPCLibraries}}MSL MPWCRuntime.Lib"			\
			"{{SharedLibraries}}InterfaceLib"				\
			$(SFIO)lib:sfio.PPC.Lib							\
			"{{MWPPCLibraries}}MSL C.PPC MPW(NL).Lib"		\
			"{{MWPPCLibraries}}MSL C++.PPC (NL).Lib"		\
			"{{SharedLibraries}}StdCLib"					\
			"{{SharedLibraries}}MathLib"					\
			"{{SharedLIbraries}}ThreadsLib"					\
			"{{SharedLibraries}}NavigationLib"				\
			"{{SharedLIbraries}}ObjectSupportLib"			\
			"{{SharedLibraries}}OpenTransportLib"			\
			"{{SharedLibraries}}OpenTptInternetLib"			\
			"{{PPCLibraries}}OpenTransportAppPPC.o"			\
			"{{PPCLibraries}}OpenTptInetPPC.o"				\
			"{{PPCLibraries}}PPCToolLibs.o"					\
			"$(IC)InternetConfigLib"						\
			"$(AEGizmos)AEGizmos4Perl.shlb.PPC"				\
			"$(DB)lib:db.Sfio.PPC.Lib"						\
			"$(XL)"XL.PPC.Lib								\
			"{{SharedLibraries}}AppleScriptLib"

MacPerlLibMrC	= 	\
			"$(GUSI)lib:GUSI_Sfio.MrC.Lib"					\
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
			"{{SharedLibraries}}NavigationLib"				\
			"{{PPCLibraries}}MrCIOStreams.o"				\
			"{{SharedLibraries}}ObjectSupportLib"			\
			"{{SharedLibraries}}StdCLib"					\
			"{{SharedLibraries}}OpenTransportLib"			\
			"{{SharedLibraries}}OpenTptInternetLib"			\
			"{{PPCLibraries}}OpenTransportAppPPC.o"			\
			"{{PPCLibraries}}OpenTptInetPPC.o"				\
			"$(IC)InternetConfigLib"						\
			"$(AEGizmos)AEGizmos4Perl.shlb.PPC"				\
			"$(DB)lib:db.Sfio.MrC.Lib"						\
			"$(XL)"XL.MrC.Lib								\
			"{{SharedLibraries}}AppleScriptLib"

MacPerlLib68K	=											\
			"$(GUSI)lib:GUSI_Sfio.68K.Lib"					\
			"$(GUSI)lib:GUSI_Core.68K.Lib"					\
			"{{MW68KLibraries}}MSL MPWRuntime.68K.Lib"		\
			"{{MW68KLibraries}}MSL Runtime68K.Lib"			\
			"{{Libraries}}AEObjectSupportLib.o"				\
			"{{Libraries}}IntEnv.o"							\
			"{{Libraries}}ToolLibs.o"						\
			"{{MW68KLibraries}}MacOS.Lib"					\
			"{{MW68KLibraries}}MSL C.68K MPW(NL_4i_8d).Lib"	\
			"{{MW68KLibraries}}MSL C++.68K (4i_8d).Lib"		\
			"{{MW68KLibraries}}MathLib68K (4i_8d).Lib"		\
			$(SFIO)lib:sfio.68K.Lib							\
			"{{Libraries}}Navigation.far.o"					\
			"{{Libraries}}OpenTransportApp.o"				\
			"{{Libraries}}OpenTransport.o"					\
			"{{Libraries}}OpenTptInet.o"					\
			-s Libraries									\
			"$(AEGizmos)AEGizmos4Perl.Lib.68K"				\
			"$(DB)lib:db.Sfio.68K.Lib"						\
			"$(XL)"XL.68K.Lib								\
			"{{Libraries}}OSACompLib.o"						\
			"$(IC)ICGlueFar.o"		

MacPerlLibSC	=	\
			"$(GUSI)lib:GUSI_Sfio.SC.Lib"					\
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
			"{{Libraries}}AEObjectSupportLib.o"				\
			"{{Libraries}}Navigation.far.o"					\
			"{{Libraries}}OpenTransport.o"					\
			"{{Libraries}}OpenTransportApp.o"				\
			"{{Libraries}}OpenTptInet.o"					\
			"$(AEGizmos)AEGizmos4Perl.Lib.SC"				\
			"$(DB)lib:db.Sfio.SC.Lib"						\
			"$(IC)ICGlueFar.o"								\
			"$(XL)"XL.SC.Lib

all	: MacPerl "MacPerl Help" MacPerlTest.Script MPDroplet

clean	:	
	Delete :Obj:Å

realclean	:	clean
	Delete -i MacPerl MacPerl.PPC MacPerl.68K MacPerl.SC MacPerl.MrC

MacPerl.PPC : Obj $(ObjectsPPC) $(PerlObjPPC)
	$(ApplLinkPPC) -name Perl  -@export $(MACPERL_SRC)perl.exp -o MacPerl.PPC :Obj:{$(ObjectsPPC)} $(PerlObjPPC) $(MacPerlLibPPC)
	MergeFragment "$(AEGizmos)AEGizmos4Perl.shlb.PPC" MacPerl.PPC
MacPerl.PPC	::	MacPerl.r MacPerl.rsrc MPTerminology.r MPBalloons.r :Obj:FontLDEF.rsrc
	$(ApplRez) MacPerl.r -d APPNAME=¶"Perl¶" -o MacPerl.PPC
	SetFile -a B MacPerl.PPC

MacPerl.MrC : Obj $(ObjectsMrC) $(PerlObjMrC)
	$(ApplLinkMrC) -fragname Perl  -@export $(MACPERL_SRC)perl.exp -o MacPerl.MrC :Obj:{$(ObjectsMrC)} $(PerlObjMrC) $(MacPerlLibMrC)
	MergeFragment "$(AEGizmos)AEGizmos4Perl.shlb.PPC" MacPerl.MrC
MacPerl.MrC	::	MacPerl.r MacPerl.rsrc MPTerminology.r MPBalloons.r :Obj:FontLDEF.rsrc
	$(ApplRez) MacPerl.r -d APPNAME=¶"Perl¶" -o MacPerl.MrC
	SetFile -a B MacPerl.MrC

MacPerl.68K : Obj $(Objects68K) $(PerlObj68K)
	$(ApplLink68K) -o MacPerl.68K :Obj:{$(Objects68K)} $(PerlObj68K) $(MacPerlLib68K)
MacPerl.68K	::	MacPerl.r MacPerl.rsrc MPTerminology.r MPBalloons.r :Obj:FontLDEF.rsrc
	$(ApplRez) MacPerl.r -o MacPerl.68K
	SetFile -a B MacPerl.68K

MacPerl.SC : Obj $(ObjectsSC) $(PerlObjSC)
	$(ApplLinkSC) -o MacPerl.SC :Obj:{$(ObjectsSC)} $(PerlObjSC) $(MacPerlLibSC)
MacPerl.SC	::	MacPerl.r MacPerl.rsrc MPTerminology.r MPBalloons.r :Obj:FontLDEF.rsrc
	$(ApplRez) MacPerl.r -d APPNAME=¶"Perl¶" -o MacPerl.SC
	SetFile -a B MacPerl.SC

macperl.exp: ::perl:perl.stubsymbols
	perl -ne 'print unless /^#|^__/' ::perl:perl.stubsymbols>macperl.exp
	echo __nw__FUl >>macperl.exp
	echo __dl__FPv >>macperl.exp

MacPerl : MacPerl.{$(MACPERL_BUILD_APPL)}
	$(MACPERL_SRC)FatBuild MacPerl $(MACPERL_INST_APPL_PPC) $(MACPERL_INST_APPL_68K)

":Obj:FontLDEF.rsrc.68K" : MPFontLDEF.c.68K.o
	$(RsrcLink68K) -t rsrc -c RSED -rt LDEF=128 -o :Obj:FontLDEF.rsrc.68K 	¶
		:Obj:MPFontLDEF.c.68K.o "{{MW68KLibraries}}"MacOS.lib

":Obj:FontLDEF.rsrc.SC" : MPFontLDEF.c.SC.o
	$(RsrcLinkSC) -t rsrc -c RSED -rt LDEF=128 -o :Obj:FontLDEF.rsrc.SC 	¶
		:Obj:MPFontLDEF.c.SC.o

":Obj:FontLDEF.rsrc" : :Obj:FontLDEF.rsrc.$(MACPERL_INST_APPL_68K)
	Duplicate :Obj:FontLDEF.rsrc.$(MACPERL_INST_APPL_68K) ":Obj:FontLDEF.rsrc"

MPTerminology.r	:	MPTerminology.aete
	:macscripts:Aete2Rez MPTerminology.aete > MPTerminology.r

MPBalloons.r	:	MPBalloons.ball
	:macscripts:Balloon2Rez MPBalloons.ball

MPGlobals.c.PPC.o	:	MPGlobals.h
MPGlobals.c.68K.o	:	MPGlobals.h

"HTML Help" 		:	MacPerl.help
#	BuildHelpIndex	"HTML Help" MacPerl.help
#	BuildLibraryIndex "MacPerl Help" $(PERL_SRC)lib:
"MacPerl Help" 		:	MacPerl.podhelp
	BuildHelpIndex	"MacPerl Help" MacPerl.podhelp
	BuildLibraryIndex "MacPerl Help" $(PERL_SRC)lib:

MacPerlTest.Script	:	MakeMacPerlTest
	MakeMacPerlTest ¶
		::perl:t:Å:Å.t> MacPerlTest.Script

MPDroplet.code.68K : MPDrop.c.68K.o
	$(ApplLink68K) -t McPp -c McPL -sym on			¶
		:Obj:MPDrop.c.68K.o								¶
		"{{MW68KLibraries}}MSL Runtime68K.Lib"			¶
		"{{MW68KLibraries}}MacOS.Lib"					¶
		"{{MW68KLibraries}}MSL C.68K MPW(NL_4i_8d).Lib"	¶
		"{{MW68KLibraries}}MathLib68K (4i_8d).Lib" -o MPDroplet.code.68K	
MPDroplet.68K : "MacPerl Extensions" MPDroplet.code.68K MPDroplet.r MPExtension.r MacPerl.rsrc
	Rez -t McPp -c McPL -d MWC -o MPDroplet.68K MPDroplet.r

MPDroplet.code.SC : MPDrop.c.SC.o
	$(ApplLinkSC) -t McPp -c McPL -sym on			¶
		:Obj:MPDrop.c.SC.o	 						¶
		"{{Libraries}}MacRuntime.o"					¶
		"{{Libraries}}Interface.o"	-o MPDroplet.code.SC
MPDroplet.SC : "MacPerl Extensions" MPDroplet.code.SC MPDroplet.r MPExtension.r MacPerl.rsrc
	Rez -t McPp -c McPL -o MPDroplet.SC MPDroplet.r

MPDroplet : MPDroplet.$(MACPERL_INST_APPL_68K)
	Duplicate -y MPDroplet.$(MACPERL_INST_APPL_68K) ":MacPerl Extensions:Droplet"

"MacPerl Extensions" :
	NewFolder "MacPerl Extensions"

Distr : all
	Distribute MacPerl.distr Mac_Perl_510r2_appl.sit

.INCLUDE : $(MACPERL_SRC)BulkBuildRules.mk
