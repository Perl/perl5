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
#	If you want both to optimise and debug with the DEC cc
#	you must have -g3, e.g. "-O4 -g3", and (re)run Configure.
#
#	Note 1: gcc can always have both -g and optimisation on.
#
#	Note 2: debugging optimised code, no matter what compiler
#	one is using, can be surprising and confusing because of
#	the optimisation tricks like code motion, code removal,
#	loop unrolling, and inlining. The source code and the
#	executable code simply do not agree any more while in
#	mid-execution, the optimiser only cares about the results.
#
#	Note 3: Configure will automatically add the often quoted
#	-DDEBUGGING for you if the -g is specified.
#
#	Note 4: There is even more optimisation available in the new
#	(GEM) DEC cc: -O5 and -fast. "man cc" will tell more about them.
#	The jury is still out whether either or neither help for Perl
#	and how much. Based on very quick testing, -fast boosts
#	raw data copy by about 5-15% (-fast brings in, among other
#	things, inlined, ahem, fast memcpy()), while on the other
#	hand searching things (index, m//, s///), seems to get slower.
#	Your mileage will vary.
#
#	Note 5: The -std is needed because the following compiled
#	without the -std and linked with -lm
#
#	#include <math.h>
#	#include <stdio.h>
#	int main(){short x=10,y=sqrt(x);printf("%d\n",y);}
#
#	will in Digital UNIX 3.* and 4.0b print 0 -- and in Digital
#	UNIX 4.0{,a} dump core: Floating point exception in the printf(),
#	the y has become a signaling NaN.
#

# If using the DEC compiler we must find out the DEC compiler style:
# the style changed between Digital UNIX (aka DEC OSF/1) 3 and
# Digital UNIX 4. The old compiler was originally from Ultrix and
# the MIPS company, the new compiler is originally from the VAX world
# and it is called GEM. Many of the options we are going to use depend
# on the compiler style.

# do NOT, I repeat, *NOT* take away that leading tab
	_DEC_cc_style=
# Configure Black Magic (TM)

case "$cc" in
*gcc*)	;; # pass
*)	# compile something small: taint.c is fine for this.
    	# the main point is the '-v' flag of 'cc'.
       	case "`cc -v -I. -c taint.c -o /tmp/taint$$.o 2>&1`" in
	*/gemc_cc*)	# we have the new DEC GEM CC
			_DEC_cc_style=new
			;;
	*)		# we have the old MIPS CC
			_DEC_cc_style=old
			;;
	esac
	# cleanup
	rm -f /tmp/taint$$.o
	;;
esac

# we want optimisation

case "$optimize" in
'')	case "$cc" in 
	*gcc*)	
		optimize='-O3'				;;
	*)	case "$_DEC_cc_style" in
		new)	optimize='-O4'			;;
		old)	optimize='-O2 -Olimit 3200'	;;
	    	esac
		;;
	esac
	;;
esac

# all compilers are ANSI
ccflags="$ccflags -DSTANDARD_C"

# be nauseatingly ANSI
case "$cc" in
gcc)	ccflags="$ccflags -ansi"
	;;
*)	ccflags="$ccflags -std"
	;;
esac

# dlopen() is in libc
libswanted="`echo $libswanted | sed -e 's/ dl / /'`"

# PW contains nothing useful for perl
libswanted="`echo $libswanted | sed -e 's/ PW / /'`"

# bsd contains nothing used by perl that is not already in libc
libswanted="`echo $libswanted | sed -e 's/ bsd / /'`"

# c need not be separately listed
libswanted="`echo $libswanted | sed -e 's/ c / /'`"

# dbm is already in libc (as is ndbm)
libswanted="`echo $libswanted | sed -e 's/ dbm / /'`"

# the basic lddlflags used always
lddlflags='-shared -expect_unresolved "*"'

# Check if it's a CMW version of OSF1,
# if so, do not hide the symbols.
test `uname -s` = "MLS+" || lddlflags="$lddlflags -hidden"

# If debugging (-g) do not strip the objects, otherwise, strip.
case "$optimize" in
	*-g*) ;; # left intentionally blank
        *) lddlflags="$lddlflags -s"
esac

#
# Unset temporary variables no more needed.
#

unset _DEC_cc_style
    
#
# History:
#
# perl5.003_27:
#
#	18-Feb-1997 Jarkko Hietaniemi <jhi@iki.fi>
#
#	* unset _DEC_cc_style and more commentary on -std.
#
#
# perl5.003_26:
#
#	15-Feb-1997 Jarkko Hietaniemi <jhi@iki.fi>
#
#	* -std and -ansi.
#
#
# perl5.003_24:
#
#	30-Jan-1997 Jarkko Hietaniemi <jhi@iki.fi>
#
#	* Fixing the note on -DDEBUGGING.
#
#	* Note on -O5 -fast.
#
#
# perl5.003_23:
#
#	26-Jan-1997 Jarkko Hietaniemi <jhi@iki.fi>
#
#	* Notes on how to do both optimisation and debugging.
#
#
#	25-Jan-1997 Jarkko Hietaniemi <jhi@iki.fi>
#
#	* Remove unneeded libraries from $libswanted: PW, bsd, c, dbm
#
#	* Restructure the $lddlflags build.
#
#	* $optimize based on which compiler we have.
#
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
