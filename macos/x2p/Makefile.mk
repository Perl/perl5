# $RCSfile: Makefile.mk,v $$Revision: 1.2 $$Date: 2000/08/21 08:22:04 $
#
# $Log: Makefile.mk,v $
# Revision 1.2  2000/08/21 08:22:04  neeri
# Build tweaks & forgotten files
#
# Revision 1.1  2000/08/14 03:39:35  neeri
# Checked into Sourceforge
#

MACPERL_SRC	= {$(PWD)}::

GUSI		= "{{GUSI}}"
SFIO		= "{{SFIO}}"

.INCLUDE : $(MACPERL_SRC)BuildRules.mk

MWCInc	+= -i ":::x2p:"
MPWInc	+= -i ":::x2p:"

.SOURCE.c		:	":" ":::x2p:" "::" 
.SOURCE.cp		:	":" ":::x2p:" "::" 
.SOURCE.y		:	":" ":::x2p:" "::" 
.SOURCE.PL		:	":::x2p:"

public = a2p s2p find2perl

private = 

manpages = a2p.man s2p.man

util =

pl = find2perl.PL s2p.PL
plextract = find2perl s2p

addedbyconf = $(plextract)

h = EXTERN.h INTERN.h ::config.h handy.h hash.h a2p.h str.h util.h

c = a2p.c hash.c str.c util.c walk.c PerlGUSIConfig.cp

Obj68K	=  {$(c)}.68K.o
ObjSC	=  {$(c)}.SC.o

Libs68K	=	"$(GUSI)lib:GUSI_Forward.68K.Lib"				\
			"{{MW68KLibraries}}MSL MPWRuntime.68K.Lib"		\
			"{{MW68KLibraries}}MSL Runtime68K.Lib"			\
			"$(GUSI)lib:GUSI_MPW.68K.Lib"					\
			"{{Libraries}}IntEnv.o"							\
			"{{Libraries}}ToolLibs.o"						\
			"{{MW68KLibraries}}MacOS.Lib"					\
			"{{MW68KLibraries}}MSL C.68K MPW(NL_4i_8d).Lib"	\
			"{{MW68KLibraries}}MSL C++.68K (4i_8d).Lib"		\
			"{{MW68KLibraries}}MathLib68K (4i_8d).Lib"		\
			"$(GUSI)lib:GUSI_Sfio.68K.Lib"					\
			$(SFIO)lib:sfio.68K.Lib							\
			"$(GUSI)lib:GUSI_Core.68K.Lib"

LibsSC	=	"$(GUSI)lib:GUSI_MPW.SC.Lib"					\
			"$(GUSI)lib:GUSI_Sfio.SC.Lib"					\
			"$(GUSI)lib:GUSI_Core.SC.Lib"					\
			"$(SFIO)lib:sfio.SC.Lib"						\
			"{{CLibraries}}CPlusLib.o"						\
			"{{CLibraries}}StdCLib.o"						\
			"{{Libraries}}MacRuntime.o"						\
			"{{Libraries}}Interface.o"						\
			"{{Libraries}}IntEnv.o"							\
			"{{Libraries}}MathLib.o"						\
			"{{Libraries}}ToolLibs.o"						\
			"{{CLibraries}}IOStreams.far.o"	

all: Obj $(public) $(private) $(util)
	echo > all

Obj: 
	NewFolder Obj

a2p.SC: $(ObjSC)
	$(LinkSC) -o a2p.SC  $(LibsSC) :Obj:{$(ObjSC)}
a2p.68K: $(Obj68K)
	$(Link68K) -o a2p.68K  $(Libs68K) :Obj:{$(Obj68K)}
	
a2p: a2p.$(MACPERL_INST_TOOL_68K)
	Duplicate -y a2p.$(MACPERL_INST_TOOL_68K) $@

# I now supply a2p.c with the kits, so the following section is
# used only if you force byacc to run by saying
# make  run_byacc

run_byacc:	
	@ echo Expect many shift/reduce and reduce/reduce conflicts
	yacc a2p.y
	Rename -y y.tab.c a2p.c

# We don't want to regenerate a2p.c, but it might appear out-of-date
# after a patch is applied or a new distribution is made.
a2p.c: a2p.y
	SetFile -m . $@

clean:
	delete -y a2p :Obj:Å

realclean: clean

$(plextract):
	::miniperl -I:::lib -I::lib :::x2p:$@.PL
