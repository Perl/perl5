# irix_6_2.sh
# original from Krishna Sethuraman, krishna@sgi.com
# Configure has been made smarter, so this is shorter than it once was.

ccflags="$ccflags -D_BSD_TYPES -D_BSD_TIME -Olimit 3000"

# We don't want these libraries.  Anyone know why?
set `echo X "$libswanted "|sed -e 's/ socket / /' -e 's/ nsl / /' -e 's/ dl / /'`
shift
libswanted="$*"

# Don't need sun crypt bsd PW under 6.2.  You *may* need to link
# with these if you want to run perl built under 6.2 on a 5.3 machine
# (I haven't checked)
set `echo X "$libswanted "|sed -e 's/ sun / /' -e 's/ crypt / /' -e 's/ bsd / /' -e 's/ PW / /'`
shift
libswanted="$*"
