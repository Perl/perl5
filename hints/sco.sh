# sco.sh
# Courtesy of Joel Rosi-Schwartz <j.schwartz@agonet.it>

# Additional SCO version info from
# Peter Wolfe	<wolfe@teloseng.com>
# Last revised
# Fri Jul 19 14:54:25 EDT 1996
# and again Tue Sep 29 16:37:25 EDT 1998
# by Andy Dougherty  <doughera@lafayette.edu>

# To use gcc, use   sh Configure -Dcc=gcc
# To use icc, use   sh Configure -Dcc=icc

# figure out what SCO version we are. The output of uname -X is
# something like:
#	System = SCO_SV
#	Node = xxxxx
#	Release = 3.2v5.0.0
#	KernelID = 95/08/08
#	Machine = Pentium
#	BusType = ISA
#	Serial = xxxxx
#	Users = 5-user
#	OEM# = 0
#	Origin# = 1
#	NumCPU = 1

# Use /bin/uname (because GNU uname may be first in $PATH and
# it does not support -X) to figure out what SCO version we are:
case `/bin/uname -X | egrep '^Release'` in
*3.2v4.*) scorls=3 ;;   # I don't know why this is 3 instead of 4.
*3.2v5.*) scorls=5 ;;
*) scorls=5 ;; # Hope the future will be compatible.
esac

# Try to use libintl.a since it has strcoll and strxfrm
libswanted="intl $libswanted"
# Try to use libdbm.nfs.a since it has dbmclose.
#
if test -f /usr/lib/libdbm.nfs.a ; then
    libswanted=`echo "dbm.nfs $libswanted " | sed -e 's/ dbm / /'`
    set X $libswanted
    shift
    libswanted="$*"
fi

# We don't want Xenix cross-development libraries
glibpth=`echo $glibpth | sed -e 's! /usr/lib/386 ! !' -e 's! /lib/386 ! !'`
xlibpth=''

# Common fix for all compilers.
ccflags="$ccflags -U M_XENIX"

# Set flags for optimization and warning levels.
case "$cc" in
*gcc*)	case "$optimize" in
	'') optimize='-O2' ;;
	esac
	;;
scocc)	;;  # Anybody know anything about this?
*)	# icc or cc  -- only relevant difference is safe level of
	# optimization.  Apparently.
	case $scorls in
	3)  ccflags="$ccflags -W0 -quiet" ;;
	*)  ccflags="$ccflags -w0 -DPERL_SCO5" ;;
	esac
	case "$optimize" in
	'') case "$cc" in
	    icc) optimize="-O1" ;;
	    *) optimize="-O0" ;;
	    esac
	    ;;
	esac
	;;
esac

# DYNAMIC LOADING:  Dynamic loading won't work with scorls=3.
# It ought to work with Release = 3.2v5.0.0 or later.
if test "$scorls" = "3" -a "X$usedl" = "X"; then
    usedl=$undef
else
    # I do not know exactly which of these are essential,
    # but this set has been recommended. --AD
    # These ought to be patched back into metaconfig, but the
    # current metaconfig units don't touch ccflags.
    # Unfortunately, the default on SCO is to produce COFF output, but
    # ELF is needed for dynamic loading, and the cc man page recommends
    # "Always specify option -b elf if ELF and COFF files might be mixed."
    # Therefore, we'll compile everything with -b elf.
    case "$cc" in
    *gcc*)  ;;
    *)	ccflags="$ccflags -b elf" ;;
    esac
    cccdlflags=none
    ccdlflags='-W l,-Bexport'
    lddlflags="$lddlflags -b elf -G"
    ldflags="$ldflags -b elf -W l,-Bexport"
    dlext='so'
    dlsrc='dl_dlopen.xs'
    d_dlerror='define'
    d_dlopen='define'
    usedl='define'
fi

# I have received one report that nm extraction doesn't work if you're
# using the scocc compiler.  This system had the following 'myconfig'
# uname='xxx xxx 3.2 2 i386 '
# cc='scocc', optimize='-O'
# You can override this with Configure -Dusenm.
case "$usenm" in
'') usenm='false' ;;
esac

# If you want to use nm, you'll probably have to use nm -p.  The
# following does that for you:
nm_opt='-p'

# I have received one report that you can't include utime.h in
# pp_sys.c.  Uncomment the following line if that happens to you:
# i_utime=undef

# Perl 5.003_05 and later try to include both <time.h> and <sys/select.h>
# in pp_sys.c, but that fails due to a redefinition of struct timeval.
# This will generate a WHOA THERE.  Accept the default.
i_sysselct=$undef
