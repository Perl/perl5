#  isc.sh
#  Interactive Unix Versions 3 and 4. 
#  Compile perl entirely in posix mode. 
#  Andy Dougherty		doughera@lafcol.lafayette.edu
#  Wed Oct  5 15:57:37 EDT 1994
#
# Use Configure -Dcc=gcc to use gcc
#
set `echo X "$libswanted "| sed -e 's/ c / /'`
shift
libswanted="$*"
case "$cc" in
*gcc*)	ccflags="$ccflags -posix"
	ldflags="$ldflags -posix"
	;;
*)	ccflags="$ccflags -Xp -D_POSIX_SOURCE"
	ldflags="$ldflags -Xp"
    	;;
esac
# Pick up dbm.h in <rpcsvc/dbm.h>
ccflags="$ccflags -I/usr/include/rpcsvc"
