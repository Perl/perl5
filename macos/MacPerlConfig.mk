#
# Build configuration for MacPerl
#
# This file may be machine generated in the future
#

#
# Build configurations
#
# Include any of the following:
#
# 68K	Metrowerks C/C++ 68K
# PPC	Metrowerks C/C++ PowerPC
# SC	MPW C 68K 
# MrC	MPW C PowerPC
#
# (CFM68K builds not yet available in this version)
#
# MACPERL_BUILD_TOOL 		Any of (68K,PPC,SC,MrC)		Builds for perl tool
# MACPERL_BUILD_APPL 		Any of (68K,PPC,SC,MrC)		Builds for MacPerl application
# MACPERL_BUILD_EXT_STATIC	Any of (68K,PPC,SC,MrC)		Builds for statically linked extensions
# MACPERL_BUILD_EXT_SHARED	Any of (PPC,MrC)			Builds for shared library extensions
#

MACPERL_BUILD_TOOL			=	68K PPC SC MrC
MACPERL_BUILD_APPL			=	68K PPC SC MrC
MACPERL_BUILD_EXT_STATIC	=	68K PPC SC MrC
MACPERL_BUILD_EXT_SHARED	= 	PPC MrC

#
# Preferred choice for installation
#	
# MACPERL_INST_TOOL_68K		One of (68K,SC)				68K build to use for fat tool
# MACPERL_INST_TOOL_PPC		One of (PPC,MrC)			PowerPC	build to use for fat tool
# MACPERL_INST_APPL_68K		One of (68K,SC)				68K build to use for fat tool
# MACPERL_INST_APPL_PPC		One of (PPC,MrC)			PowerPC	build to use for fat tool
# MACPERL_INST_EXT_PPC		One of (PPC,MrC)			PowerPC build to use for shared library extensions
#

MACPERL_INST_TOOL_68K		=	68K
MACPERL_INST_TOOL_PPC		=	PPC
MACPERL_INST_APPL_68K		=	68K
MACPERL_INST_APPL_PPC		=	PPC
MACPERL_INST_EXT_PPC		=	PPC

#
# Metrowerks MPW Configuration
#
# Choose one of the following:
#
# a) "Old" layout, CodeWarrior headers and universal headers all in one directory
#
#CWANSIInc  = 	{{MWCIncludes}}
#
# a) "New" layout, CodeWarrior headers in CWANSIIncludes
#
CWANSIInc  = 	{{CWANSIIncludes}}
#

#CWANSIInc	=	{{CWANSIIncludes}} "Bourque:Prog:Metrowerks:Metrowerks¶ CodeWarrior:MSL:MSL_C++:MSL_Common:Include:"
