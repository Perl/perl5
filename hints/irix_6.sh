# hints/irix_6_2.sh
#
# original from Krishna Sethuraman, krishna@sgi.com
#
# Updated Mon Jul 22 14:52:25 EDT 1996
# 	Andy Dougherty <doughera@lafcol.lafayette.edu>
# 	with help from Dean Roehrich <roehrich@cray.com>.
#   cc -n32 update info from Krishna Sethuraman, krishna@sgi.com.
#       additional update from Scott Henry, scotth@sgi.com

# Use   sh Configure -Dcc='cc -n32' to try compiling with -n32.
#     or -Dcc='cc -n32 -mips3' (or -mips4) to force (non)portability
# Don't bother with -n32 unless you have the 7.1 or later compilers.
#     But there's no quick and light-weight way to check in 6.2.

case "$cc" in
*"cc -n32"*)
	ld=ld
	ccflags="$ccflags -D_BSD_TYPES -D_BSD_TIME -woff 1009,1110,1184 -OPT:Olimit=0"
#	optimize='none'	# for pre-7.1 compilers. Miniperl core dumps with -O
	optimize='-O3'	# This works with the 7.1 and later compilers
	ldflags=' -L/usr/local/lib -L/usr/lib32 -L/lib32'
	cccdlflags=' '
	lddlflags="-n32 -shared"
	libc='/usr/lib32/libc.so'
	plibpth='/usr/lib32 /lib32 /usr/ccs/lib'
	nm_opt='-p'
	nm_so_opt='-p'
	;;
*)
	# this is needed to force the old-32 paths
	#  since the system default can be changed.
	ccflags="$ccflags -32 -D_BSD_TYPES -D_BSD_TIME -Olimit 3000"
	;;
esac

pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'

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
#  Actually, the only libs that you want are '-lm'.  Everything else
# you need is in libc.  You do also need '-lbsd' if you choose not
# to use the -D_BSD_* defines.  Note that as of 6.2 the only
# difference between '-lmalloc' and '-lc' malloc is the debugging
# and control calls. -- scotth@sgi.com

set `echo X "$libswanted "|sed -e 's/ sun / /' -e 's/ crypt / /' -e 's/ bsd / /' -e 's/ PW / /'`
shift
libswanted="$*"

