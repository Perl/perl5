# hints/dec_osf.sh

#
# How to make a DEBUGGING VERSION of perl for DECs cc compiler
#
#	If you want to debug perl or want to send a
#	stack trace for inclusion into an bug report, call
#	Configure with the additional argument  -Doptimize=-g2
#	or uncomment this assignment to "optimize":
#
#optimize=-g2
#
#	and (re)run Configure.  Note: Configure will automatically
#       add the often quoted -DDEBUGGING for you)
#

case "$optimize" in
'')	case "$cc" in 
	*gcc*)	;;
	*)	optimize='-O2 -Olimit 3200' ;;
	esac
	;;
esac

# both compilers are ANSI
ccflags="$ccflags -DSTANDARD_C"

# dlopen() is in libc
libswanted="`echo $libswanted | sed -e 's/ dl / /'`"

# Check if it's a CMW version of OSF1
# '-s' strips shared libraries, not useful for debugging
if test `uname -s` = "MLS+"; then
    case "$optimize" in
        *-g*) lddlflags='-shared -expect_unresolved "*"' ;;
        *)    lddlflags='-shared -expect_unresolved "*" -s' ;;
    esac
else
    case "$optimize" in
        *-g*) lddlflags='-shared -expect_unresolved "*" -hidden' ;;
        *)    lddlflags='-shared -expect_unresolved "*" -s -hidden' ;;
    esac
fi

#
# History:
#
# perl5.003_22:
#
#	23-Jan-1997 Achim Bohnet <ach@rosat.mpe-garching.mpg.de>
#
#	* Added comments 'how to create a debugging version of perl'
#
#	* Fixed logic of this script to prevent stripping of shared
#         objects by the loader (see ld man page for -s) is debugging
#         is set via the -g switch.
#
#
#	21-Jan-1997 Achim Bohnet <ach@rosat.mpe-garching.mpg.de>
#
#	* now 'dl' is always removed from libswanted. Not only if
#	  optimize is an empty string.
#	 
#
#	17-Jan-1997 Achim Bohnet <ach@rosat.mpe-garching.mpg.de>
#
#	* Removed 'dl' from libswanted: When the FreePort binary
#	  translator for Sun binaries is installed Configure concludes
#	  that it should use libdl.x.yz.fpx.so :-(
#	  Because the dlopen, dlclose,... calls are in the
#	  C library it not necessary at all to check for the
#	  dl library.  Therefore dl is removed from libswanted.
#	
#
#	1-Jan-1997 Achim Bohnet <ach@rosat.mpe-garching.mpg.de>
#	
#	* Set -Olimit to 3200 because perl_yylex.c got too big
#	  for the optimizer.
#

#---------------------------------------------------------------------

#
# Where configure gets it wrong:
#
#	- FUNCTIONS PROTOTYPES: Because the following search
#
#		% grep _NO_PROTO /usr/include/sys/signal.h
#	  	#ifndef _NO_PROTO
#		#else   /* _NO_PROTO */
#		#endif  /* _NO_PROTO */
#	  	%
#	  
#	  is successful and because _NO_PROTO is not included already
#	  in the ccflags, Configure adds -D_NO_PROTO to ccflags. :-(
#	
