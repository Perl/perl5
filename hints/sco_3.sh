# sco_3.sh 
# Courtesy of Joel Rosi-Schwartz <joel@ftechne.co.uk>
# To use gcc, do     Configure -Dcc=gcc
#
# Try to use libintl.a since it has strcoll and strxfrm
libswanted="intl $libswanted"
# Try to use libdbm.nfs.a since it has dbmclose.
# 
if test -f /usr/lib/libdbm.nfs.a ; then
    libswanted=`echo "dbm.nfs $libswanted " | sed -e 's/ dbm / /'`
fi
set X $libswanted
shift
libswanted="$*"
# 
# We don't want Xenix cross-development libraries
glibpth=`echo $glibpth | sed -e 's! /usr/lib/386 ! !' -e 's! /lib/386 ! !'`
xlibpth=''
# 
case "$cc" in
gcc)
	ccflags="$ccflags -U M_XENIX"
	optimize="$optimize -O2"
	;;
*)
	ccflags="$ccflags -W0 -U M_XENIX"
	;;
esac
i_varargs=undef
nm_opt='-p'
