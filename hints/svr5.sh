# svr5 hints, System V Release 5.x
# Last modified 1999/09/21 by Boyd Gerber, gerberb@zenez.com

# Use Configure -Dcc=gcc to use gcc.
case "$cc" in
'') cc='/bin/cc'
    test -f $cc || cc='/usr/ccs/bin/cc'
    ;;
  *)
    case "$gccversion" in
      *2.95*) 
        ccflags='-fno-strict-aliasing'
      ;;
      *);;
    esac
  ;;
esac

# want_ucb=''
# want_dbm='yes'
want_gdbm='yes'

# We include support for using libraries in /usr/ucblib, but the setting
# of libswanted excludes some libraries found there.  If you run into
# problems, you may have to remove "ucb" from libswanted.  Just delete
# the comment '#' from the sed command below.
# ldflags='-L/usr/ccs/lib -L/usr/ucblib'
# ccflags='-I/usr/include -I/usr/ucbinclude'
# Don't use problematic libraries:
libswanted=`echo " $libswanted " | sed -e 's/ malloc / /'` # -e 's/ ucb / /'`
# libmalloc.a - Probably using Perl's malloc() anyway.
# libucb.a - Remove it if you have problems ld'ing.  We include it because
#   it is needed for ODBM_File and NDBM_File extensions.

if [ "$want_ucb" ] ; then 
    ldflags= '-L/usr/ccs/lib -L/usr/ucblib'
    ccflags='-I/usr/include -I/usr/ucbinclude'
  if [ -r /usr/ucblib/libucb.a ]; then	# If using BSD-compat. library:
    d_Gconvert='gcvt((x),(n),(b))'	# Try gcvt() before gconvert().
    # Use the "native" counterparts, not the BSD emulation stuff:
    d_bcmp='undef' d_bcopy='undef' d_bzero='undef' d_safebcpy='undef'
    d_index='undef' d_killpg='undef' d_getprior='undef' d_setprior='undef'
    d_setlinebuf='undef' 
    # d_setregid='undef' d_setreuid='undef'  # ???
  fi
else
#    libswanted=`echo " $libswanted " | sed -e 's/ ucb / /' -e 's/ dbm / /'`
    libswanted=`echo " $libswanted " | sed -e 's/ ucb / /'`
    glibpth=`echo " $glibpth " | sed -e 's/ \/usr\/ucblib / /'`

    # a non ucb native version of libdbm for /usr/local is available from 
    # http://www.sco.com/skunkware 
    # if its installed (and not overidden) we'll use it.
    if [ ! -f /usr/local/lib/libdbm.so -o ! "$want_dbm" ] ; then
        libswanted=`echo " $libswanted " | sed -e 's/ dbm / /'`
    fi
fi

if [ "$want_gdbm" -a -f /usr/local/lib/libgdbm.so ] ; then 
    i_gdbm='define'
else
    i_gdbm='undef'
   libswanted=`echo " $libswanted " | sed -e 's/ gdbm / /'`
fi

# Don't use problematic libraries:
#   libmalloc.a - Probably using Perl's malloc() anyway.
#   libc:  on UW7 don't want -lc explicitly - cc gives warnings/errors
libswanted=`echo " $libswanted " | sed -e 's/ malloc / /' -e 's/ c / /'`

# remove /shlib and /lib from library search path as both symlink to /usr/lib
# where runtime shared libc is 
glibpth=`echo " $glibpth " | sed -e 's/ \/shlib / /' -e 's/ \/lib / /`

# UnixWare has /usr/lib/libc.so.1, /usr/lib/libc.so.1.1, and
# /usr/ccs/lib/libc.so.  Configure chooses libc.so.1.1 while it
# appears that /usr/ccs/lib/libc.so contains more symbols:
#
# Try the following if you want to use nm-extraction.  We'll just
# skip the nm-extraction phase, since searching for all the different
# library versions will be hard to keep up-to-date.
#
# if [ "" = "$libc" -a -f /usr/ccs/lib/libc.so -a \
#   -f /usr/lib/libc.so.1 -a -f /usr/lib/libc.so.1.1 ]; then
#     if nm -h /usr/ccs/lib/libc.so | egrep '\<_?select$' >/dev/null; then
# 	if nm -h /usr/lib/libc.so.1 | egrep '\<_?select$'` >/dev/null ||
# 	   nm -h /usr/lib/libc.so.1.1 | egrep '\<_?select$'` >/dev/null; then
# 	    :
# 	else
# 	    libc=/usr/ccs/lib/libc.so
# 	fi
#     fi
# fi
#
#  Don't bother with nm.  Just compile & link a small C program.
case "$usenm" in
'') usenm=false;;
esac

# Broken C-Shell tests (Thanks to Tye McQueen):
# The OS-specific checks may be obsoleted by the this generic test.
	sh_cnt=`sh -c 'echo /*' | wc -c`
	csh_cnt=`csh -f -c 'glob /*' 2>/dev/null | wc -c`
	csh_cnt=`expr 1 + $csh_cnt`
if [ "$sh_cnt" -ne "$csh_cnt" ]; then
    echo "You're csh has a broken 'glob', disabling..." >&2
    d_csh='undef'
fi

# Unixware-specific problems.  The undocumented -X argument to uname 
# is probably a reasonable way of detecting UnixWare.  
# UnixWare has a broken csh.  (This might already be detected above).
# Configure can't detect memcpy or memset on Unixware 2 or 7
#
#    Leave leading tabs on the next two lines so Configure doesn't 
#    propagate these variables to config.sh
	uw_ver=`uname -v`
	uw_isuw=`uname -X 2>&1 | grep Release`

if [ "$uw_isuw" = "Release = 5" ]; then
   case $uw_ver in
   7*)
	d_csh='undef'
	d_memcpy='define'
	d_memset='define'
	stdio_cnt='((fp)->__cnt)'
	d_stdio_cnt_lval='define'
	stdio_ptr='((fp)->__ptr)'
	d_stdio_ptr_lval='define'
	;;
   esac
fi

###############################################################
# Dynamic loading section:
#
# ccdlflags : must tell the linker to export all global symbols
# cccdlflags: must tell the compiler to generate relocatable code
# lddlflags : must tell the linker to output a shared library
#
# /usr/local/lib is added for convenience, since additional libraries
# are usually put there 
#
# use shared perl lib    
useshrplib='true'

case "$cc" in
       *gcc*)
           ccdlflags='-Xlinker -Bexport -L/usr/local/lib'
           cccdlflags='-fpic'
           lddlflags='-G -L/usr/local/lib'
        ;;
        *)
           ccdlflags='-Wl,-Bexport -L/usr/local/lib'
           cccdlflags='-KPIC'
           lddlflags='-G -Wl,-Bexport -L/usr/local/lib'
        ;;
esac

###############################################################
# Use dynamic loading
usedl='define'
dlext='so'
dlsrc='dl_dlopen.xs'

# Configure may fail to find lstat() since it's a static/inline function
# in <sys/stat.h> on Unisys U6000 SVR4, UnixWare 2.x, and possibly other
# SVR4 derivatives.  (Though UnixWare has it in /usr/ccs/lib/libc.so.)
d_lstat=define


# DDE SMES Supermax Enterprise Server
case "`uname -sm`" in
"UNIX_SV SMES")
    # the *grent functions are in libgen.
    libswanted="$libswanted gen"
    # csh is broken (also) in SMES
    # This may already be detected by the generic test above.
    d_csh='undef'
    case "$cc" in
    *gcc*) ;;
    *)	# for cc we need -K PIC (not -K pic)
 	cccdlflags="$cccdlflags -K PIC"
	;;
    esac
    ;;
esac

# This script UU/usethreads.cbu will get 'called-back' by Configure 
# after it has prompted the user for whether to use threads.
cat > UU/usethreads.cbu <<'EOCBU'
case "$usethreads" in
$define|true|[yY]*)
        ccflags="$ccflags"
        set `echo X "$libswanted "| sed -e 's/ c / pthread c /'`
        shift
        libswanted="$*"
  case "$cc" in
       *gcc*)
           ccflags="-D_REENTRANT $ccflags -fpic -pthread"
           cccdlflags='-fpic'
           lddlflags='-pthread -G -L/usr/local/lib '
        ;;
        *)
           ccflags="-D_REENTRANT $ccflags -KPIC -Kthread"
           ccdlflags='-Kthread -Wl,-Bexport -L/usr/local/lib'
           cccdlflags='-KPIC -Kthread'
           lddlflags='-G -Kthread -Wl,-Bexport -L/usr/local/lib'
           ldflags='-Kthread -L/usr/local/lib -L/usr/gnu/lib'
        ;;
  esac
esac
EOCBU

# End of Unixware-specific tests.
# Configure may fail to find lstat() since it's a static/inline function
# in <sys/stat.h> on Unisys U6000 SVR4, UnixWare 2.x, and possibly other
# SVR4 derivatives.  (Though UnixWare has it in /usr/ccs/lib/libc.so.)
d_lstat=define

d_suidsafe='define'	# "./Configure -d" can't figure this out easilly

