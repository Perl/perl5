#
# Build rules for dmake
#
# All your configuration needs should be covered in MacPerlConfig.mk
#

MACPERL_SRC	*= 	"$(PWD):"

.INCLUDE	:	$(MACPERL_SRC)MacPerlConfig.mk

#
# Tools
#

MAKE	 	= BuildProgram

#
# We try to support both CodeWarrior MPW Include models
#
MWCOptimize    *= 
MWCPPCOptimize *= ${MWCOptimize}
MWCPPCOptimize *= ${MWCOptimize}
MPWOptimize    *= 
MRCOptimize    *= ${MPWOptimize}
SCOptimize     *= ${MPWOptimize}

CInc		=	
MWCInc		= 	-nosyspath -convertpaths -nodefaults -i : -i :: -i {{SFIO}}include: -i {{GUSI}}include: -i "$(CWANSIInc)" -i "{{CIncludes}}"
MPWInc		= 	-i : -i :: -i {{SFIO}}include: -i {{GUSI}}include: -i "{{CIncludes}}"
COpt		=	-d MACOS_TRADITIONAL $(DOpt) -sym on -d DEBUGGING
Opt68K		=	-model far -mc68020 -mbg on
OptPPC		=	-tb on
MWCOpt		=	${COpt} ${MWCInc} ${CInc} -w off
# -w 2,3,6,7,35,29
MPWOpt		=	${COpt} ${MPWInc} ${CInc} -includes unix -w off
MPWCpOpt	=	-i "{{STLport}}stl:" -ER -bool on
C68K		=	MWC68K ${MWCOpt} ${Opt68K} ${MWC68KOptimize}
CPPC		=	MWCPPC ${MWCOpt} ${OptPPC} ${MWCPPCOptimize}
CSC			=	SC ${MPWOpt} ${Opt68K} ${SCOptimize}
CMRC		=	MrC ${SFIOInc} ${MPWOpt} ${OptPPC} ${MRCOptimize}
CpSC		=	SCpp ${MPWOpt} ${MPWCpOpt} ${Opt68K}
CpMRC		=	MrCpp ${SFIOInc} ${MPWOpt} ${MPWCpOpt} ${OptPPC}
ROptions 	= 	-i : -i "{{GUSI}}src:" -i "{{GUSI}}include:"
Lib68K		=	MWLink68K -xm library -sym on
LibPPC		=	MWLinkPPC -xm library -sym on
LibSC		=	Lib -sym on -d
#LibMrC		=	PPCLink -xm l -sym on -d
LibMrC		=	PPCLink -xm l -sym big -d
LOpt		= 	-sym on 
MWLOpt		= 	${LOpt} -xm mpwtool -d -warn
Link68K		=	MWLink68K ${MWLOpt} -model far
LinkPPC		=	MWLinkPPC ${MWLOpt}
#MPWLOpt	=	${LOpt} -c 'MPS ' -t MPST -w -mf
MPWLOpt		=	-c 'MPS ' -t MPST -w -mf
#LinkSC		=	Link ${MPWLOpt}  -model far
LinkSC		=	Link ${LOpt} ${MPWLOpt}  -model far
#LinkMrC	= 	PPCLink ${MPWLOpt}
LinkMrC		= 	PPCLink -sym big ${MPWLOpt}
# nodup
SharedLibPPC=	MWLinkPPC -xm sharedlibrary -sym on -msg nowarn
SharedLibMrC= 	PPCLink -xm sharedlibrary -sym off -d

#
# Directories
#

.INIT			:	Obj


.SOURCE.o		:	":Obj:"
.SOURCE.68K		:	":Obj:"
.SOURCE.SC		:	":Obj:"
.SOURCE.CFM68K	:	":Obj:"
.SOURCE.680		:	":Obj:"
.SOURCE.PPC		:	":Obj:"
.SOURCE.c		:	":" "::" 
.SOURCE.cp		:	":" 
.SOURCE.y		:	"::"

#
# Pattern rules
#

%.c.68K.o		:	%.c
	$(C68K) $< -o $@
%.cp.68K.o		:	%.cp
	$(C68K) $< -o $@
%.c.PPC.o		:	%.c
	$(CPPC) $< -o $@
%.cp.PPC.o		:	%.cp
	$(CPPC) $< -o $@
%.c.SC.o		:	%.c
	$(CSC) $< -o $@
%.cp.SC.o		:	%.cp
	$(CpSC) $< -o $@
%.c.MrC.o		:	%.c
	$(CMRC) $< -o $@
%.cp.MrC.o		:	%.cp
	$(CpMRC) $< -o $@
