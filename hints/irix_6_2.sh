# hints/irix_6_2.sh
#
# original from Krishna Sethuraman, krishna@sgi.com
#
# Updated Mon Jul 22 14:52:25 EDT 1996
# 	Andy Dougherty <doughera@lafcol.lafayette.edu>
# 	with help from Dean Roehrich <roehrich@cray.com>.
#   cc -n32 update info from Krishna Sethuraman, krishna@sgi.com.

# Use   sh Configure -Dcc='cc -n32' to try compiling with -n32.

case "$cc" in
*"cc -n32"*)
	ld=ld
	ccflags="$ccflags -D_BSD_TYPES -D_BSD_TIME -woff 1009,1110,1184 -OPT:fprop_limit=1500"
	optimize='none'  # Miniperl core dumps with -O
	pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'
	lddlflags="-n32 -shared"
	ldflags=' -L/usr/local/lib -L/usr/lib32 -L/lib32'
	libc='/usr/lib32/libc.so'
	plibpth='/usr/lib32 /lib32 /usr/ccs/lib'

	nm_opt='-p'
	nm_so_opt='-p'
	cccdlflags=' '
	;;
*)
	ccflags="$ccflags -D_BSD_TYPES -D_BSD_TIME -Olimit 3000"
	;;
esac

# We don't want these libraries.  Anyone know why?
set `echo X "$libswanted "|sed -e 's/ socket / /' -e 's/ nsl / /' -e 's/ dl / /'`
shift
libswanted="$*"

# I have conflicting reports about the sun, crypt, bsd, and PW
# libraries on Irix 6.2.
#
# One user rerports:
# Don't need sun crypt bsd PW under 6.2.  You *may* need to link
# with these if you want to run perl built under 6.2 on a 5.3 machine
# (I haven't checked)
#
# Another user reported that if he included those libraries, a large number
# of the tests failed (approx. 20-25) and he would get a core dump. To
# make things worse, test results were inconsistent, i.e., some of the
# tests would pass some times and fail at other times.
# The safest thing to do seems to be to eliminate them.
#
set `echo X "$libswanted "|sed -e 's/ sun / /' -e 's/ crypt / /' -e 's/ bsd / /' -e 's/ PW / /'`
shift
libswanted="$*"

