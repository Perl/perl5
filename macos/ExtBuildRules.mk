#
# Additional build rules for MacPerl extensions
#
# All your configuration needs should be covered in MacPerlConfig.mk
#

COpt     += $(DEFINE) -i $(MACPERL_SRC) -i $(PERL_SRC) $(INC) 
PERL_LIB = $(PERL_SRC)lib:
PERL_INC = $(PERL_SRC)
PERL_INST= :blib:lib:
PERL     = $(MACPERL_SRC)miniperl
# Where is the Config.pm that we are using/depend on
CONFIGDEP= $(PERL_LIB)Config.pm
DLSRC    = dl_mac.xs

EXPORT_FILE	*= $(BASEEXT).exp
EXPORTS	 	*= -@export $(EXPORT_FILE)

FULLEXT	*=	$(NAME)
BASEEXT *= 	$(NAME)
ROOTEXT *=

# Where to put things:
INST_LIBDIR			= $(PERL_INST)$(ROOTEXT)
INST_AUTODIR_PPC	= $(PERL_INST)MacPPC:auto:$(FULLEXT):
INST_DYNAMIC_PPC 	= $(INST_AUTODIR_PPC)$(BASEEXT)

AUTOSPLITFILE	:= $(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) -e 'use AutoSplit; AutoSplit::autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1) ;'
LNS				:= $(PERL) -e 'symlink($$ARGV[0], $$ARGV[1])'
MKPATH			:= $(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) -e 'use File::Path; mkpath(\@ARGV, 1);'
FILTER			:= $(PERL) -e '$$pat = shift @ARGV; print "\"", join("\"\n\"", grep(/$$pat/, @ARGV)), "\"\n";'
NFILTER			:= $(PERL) -e '$$pat = shift @ARGV; print "\"", join("\"\n\"", grep($$_ !~ /$$pat/, @ARGV)), "\"\n";'
XSUBPP			:= $(PERL_LIB)ExtUtils:xsubpp
XSUBPPARGS		:= $(TYPEMAPS:^"-typemap ") $(XSPROTOARG)
CP              := Duplicate -y 
RM_F			:= $(MACPERL_SRC)SafeDel
RM_RF			:= $(MACPERL_SRC)SafeDel
MV			    := Rename -y
TOUCH 			:= SetFile -m .

SOURCE 		*= $(BASEEXT).c $(MORE_SRC)
MODULES		*= $(BASEEXT).pm $(MORE_MODS)

Objects68K		=  {$(SOURCE)}.68K.o
ObjectsPPC		=  {$(SOURCE)}.PPC.o
ObjectsSC		=  {$(SOURCE)}.SC.o
ObjectsMrC		=  {$(SOURCE)}.MrC.o
LibrariesPPC	:=  $(MACLIBS_PPC) $(MACLIBS_ALL_PPC) $(MACLIBS_SHARED)  
LibrariesMrC	:=  $(MACLIBS_MRC) $(MACLIBS_ALL_PPC) $(MACLIBS_SHARED)  

%.c .PRECIOUS : %.xs
	Set Echo 1
	$(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) $(XSUBPP) $(XSUBPPARGS) $< >xstmp.c && Rename -y xstmp.c $@
%.cp .PRECIOUS : %.xs
	Set Echo 1
	$(PERL) -I$(MACPERL_LIB) -I$(PERL_LIB) $(XSUBPP) $(XSUBPPARGS) $< >xstmp.cp && Rename -y xstmp.c $@

static:  $(BASEEXT).Lib.{$(MACPERL_BUILD_EXT_STATIC)}
dynamic: $(BASEEXT).shlb.{$(MACPERL_BUILD_EXT_SHARED)}

do_install_static: $(MODULES) $(XS_FILES)
	$(MACPERL_SRC)InstallBLIB "$(NAME)" "$(MKPATH)" $(MODULES) $(XS_FILES)
do_install_dynamic: do_install_static $(BASEEXT).shlb.$(MACPERL_INST_EXT_PPC)
	$(MKPATH) $(INST_AUTODIR_PPC)
	Duplicate -y $(BASEEXT).shlb.$(MACPERL_INST_EXT_PPC) $(INST_DYNAMIC_PPC)

DYNAMIC_STDLIBS_PPC		*= 							\
	"$(MACPERL_SRC)PerlStub" 						\
	"{{SharedLibraries}}InterfaceLib"				\
	"{{SharedLibraries}}MathLib"					\
	"{{MWPPCLibraries}}MSL ShLibRuntime.Lib" 		\
	"{{MWPPCLibraries}}MSL RuntimePPC.Lib"			\
	"{{MWPPCLibraries}}MSL C.PPC (NL).Lib"			\
	"{{MWPPCLibraries}}MSL C++.PPC (NL).Lib"

DYNAMIC_STDLIBS_MRC		*= 							\
	"$(MACPERL_SRC)PerlStub" 						\
	"{{SharedLibraries}}InterfaceLib"				\
	"{{SharedLibraries}}StdCLib"				\
	"{{SharedLibraries}}MathLib"					\
	"{{PPCLibraries}}MrCPlusLib.o"					\
	"{{PPCLibraries}}PPCCRuntime.o"

$(BASEEXT).Lib.68K : Objects68K
	$(Lib68K) -o $(BASEEXT).Lib.68K :Obj:{$(Objects68K)}
$(BASEEXT).Lib.PPC : ObjectsPPC
	$(LibPPC) -o $(BASEEXT).Lib.PPC :Obj:{$(ObjectsPPC)}
$(BASEEXT).Lib.SC : ObjectsSC
	$(LibSC) -o $(BASEEXT).Lib.SC :Obj:{$(ObjectsSC)}
$(BASEEXT).Lib.MrC : ObjectsMrC
	$(LibMrC) -o $(BASEEXT).Lib.MrC :Obj:{$(ObjectsMrC)}
$(BASEEXT).shlb.PPC : ObjectsPPC $(EXPORT_FILE)
	$(SharedLibPPC) $(EXPORTS) -name $(BASEEXT) -o $(BASEEXT).shlb.PPC :Obj:{$(ObjectsPPC)} $(DYNAMIC_STDLIBS_PPC) $(LibrariesPPC)
$(BASEEXT).shlb.MrC : ObjectsMrC $(EXPORT_FILE)
	$(SharedLibMrC) $(EXPORTS) -fragname $(BASEEXT) -o $(BASEEXT).shlb.MrC :Obj:{$(ObjectsMrC)} $(DYNAMIC_STDLIBS_MRC) $(LibrariesMrC)

clean: 
	$(RM_RF) ':Obj:Å'
	
realclean:
	$(RM_RF) 'Å.Lib.Å' 'Å.shlb.Å'

dist:
	$(RM_RF) $(DISTNAME)
	$(MKPATH) $(DISTNAME)
	$(CP) blib $(DISTNAME)
	if `Exists t != ""`
		$(CP) t $(DISTNAME)
	End
	$(CP) Makefile.PL $(DISTNAME)
	$(CP) Makefile.mk $(DISTNAME)
	$(RM_RF) $(DISTNAME).sit
	Stuff -o $(DISTNAME).sit $(DISTNAME)

.PHONY : Objects68K ObjectsPPC ObjectsSC ObjectsMrC

ProcessPL :: 
	echo > ProcessPL

Objects68K: Obj ProcessPL $(Objects68K)
ObjectsPPC: Obj ProcessPL $(ObjectsPPC)
ObjectsSC:  Obj ProcessPL $(ObjectsSC)
ObjectsMrC: Obj ProcessPL $(ObjectsMrC)
