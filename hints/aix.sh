# hints/aix.sh
# AIX 3.x.x hints thanks to Wayne Scott <wscott@ichips.intel.com>
# AIX 4.1 hints thanks to Christopher Chan-Nui <channui@austin.ibm.com>.
# AIX 4.1 pthreading by Christopher Chan-Nui <channui@austin.ibm.com> and
#         Jarkko Hietaniemi <jhi@iki.fi>.
# Merged on Mon Feb  6 10:22:35 EST 1995 by
#   Andy Dougherty  <doughera@lafcol.lafayette.edu>

#
# Contact dfavor@corridor.com for any of the following:
#
#    - AIX 43x and above support
#    - gcc + threads support
#    - socks support
#
# Apr 99 changes:
#
#    - use nm in AIX 43x and above
#    - gcc + threads now builds
#    - added support for socks, when Dccflags=-DSOCKS specified
#
# Notes:
#
#    - shared libperl support is tricky. if ever libperl.a ends up
#      in /usr/local/lib/* it can override any subsequent builds of
#      that same perl release. to make sure you know where the shared
#      libperl.a is coming from do a 'dump -Hv perl' and check all the
#      library search paths in the loader header.
#
#      it would be nice to warn the user if a libperl.a exists that is
#      going to override the current build, but that would be complex.
#
#      better yet, a solid fix for this situation should be developed.
#

# Configure finds setrgid and setruid, but they're useless.  The man
# pages state:
#    setrgid: The EPERM error code is always returned.
#    setruid: The EPERM error code is always returned. Processes cannot
#             reset only their real user IDs.
d_setrgid='undef'
d_setruid='undef'

alignbytes=8

usemymalloc='n'

# Intuiting the existence of system calls under AIX is difficult,
# at best; the safest technique is to find them empirically.

# AIX 4.3.* and above default to using nm for symbol extraction
case "$osvers" in
   3.*|4.1.*|4.2.*)
      usenm='undef'
      ;;
   *)
      usenm='true'
      ;;
esac

so="a"
dlext="so"

# Trying to set this breaks the POSIX.c compilation

# Make setsockopt work correctly.  See man page.
# ccflags='-D_BSD=44'

# uname -m output is too specific and not appropriate here
case "$archname" in
'') archname="$osname" ;;
esac

case "$osvers" in
3*) d_fchmod=undef
    ccflags="$ccflags -D_ALL_SOURCE"
    ;;
*)  # These hints at least work for 4.x, possibly other systems too.
    ccflags="$ccflags -D_ALL_SOURCE -D_ANSI_C_SOURCE -D_POSIX_SOURCE"
    case "$cc" in
     *gcc*) ;;
     *) ccflags="$ccflags -qmaxmem=8192" ;;
    esac
    nm_opt='-B'
    ;;
esac

# These functions don't work like Perl expects them to.
d_setregid='undef'
d_setreuid='undef'

# Changes for dynamic linking by Wayne Scott <wscott@ichips.intel.com>
#
# Tell perl which symbols to export for dynamic linking.
case "$cc" in
*gcc*) ccdlflags='-Xlinker -bE:perl.exp' ;;
*) ccdlflags='-bE:perl.exp' ;;
esac

# The first 3 options would not be needed if dynamic libs. could be linked
# with the compiler instead of ld.
# -bI:$(PERL_INC)/perl.exp  Read the exported symbols from the perl binary
# -bE:$(BASEEXT).exp        Export these symbols.  This file contains only one
#                           symbol: boot_$(EXP)  can it be auto-generated?
case "$osvers" in
3*) 
    lddlflags='-H512 -T512 -bhalt:4 -bM:SRE -bI:$(PERL_INC)/perl.exp -bE:$(BASEEXT).exp -e _nostart'
    ;;
*) 
    lddlflags='-bhalt:4 -bM:SRE -bI:$(PERL_INC)/perl.exp -bE:$(BASEEXT).exp -b noentry'
    ;;
esac

#
# if $ccflags contains -DSOCKS, then add socks library support.
#
# SOCKS support also requires each source module with socket support
# add the following lines directly after the #include <socket.h>:
#
#   #ifdef SOCKS
#   #include <socks.h>
#   #endif
#
# It is expected that libsocks.a resides in /usr/local/lib and that
# socks.h resides in /usr/local/include. If these files live some
# different place then modify 
#

for arg in $ccflags ; do

   if [ "$arg" = "-DSOCKS" ] ; then

      sockslib=socks5
      incpath=/usr/local/include
      libpath=/usr/local/lib

      echo >&4 "SOCKS using $incpath/socks.h and $libpath/lib${sockslib}.a"
      echo >&4 "SOCKS requires source modifications. #include <socket.h> must change to:"
      echo >&4
      echo >&4 "   #include <socket.h>"
      echo >&4 "   #ifdef SOCKS"
      echo >&4 "   #include <socks.h>"
      echo >&4 "   #endif"
      echo >&4
      echo >&4 "in some or all of the following files:"
      echo >&4

      for arg in `find . \( -name '*.c' -o -name '*.xs' -o -name '*.h' \) \
                         -exec egrep -l '#.*include.*socket\.h' {} \; | \
                         egrep -v "win32|vms|t/lib|Socket.c` ; do
         echo >&4 "   $arg"
      done

      echo >&4

      lddlflags="$lddlflags -l$sockslib"

      # setting $libs here breaks the optional libraries search
      # for some reason, so use $libswanted instead
      #libs="$libs -lsocks5"

      libswanted="$libswanted $sockslib"

      #
      # path for include file
      #

      locincpth="$locincpath /usr/local/include"

      #
      # path for library not needed, if in /usr/local/lib as that
      # directory is already searched.
      #

      #loclibpth="$loclibpath /usr/local/lib"

      break

   fi

done

lddllibc="-lc"

# This script UU/usethreads.cbu will get 'called-back' by Configure 
# after it has prompted the user for whether to use threads.
cat > UU/usethreads.cbu <<'EOCBU'
case "$usethreads" in
$define|true|[yY]*)
        ccflags="$ccflags -DNEED_PTHREAD_INIT"
        case "$cc" in
        gcc) ;;
        cc_r) ;;
        cc|xlc_r) 
	    echo >&4 "Switching cc to cc_r because of POSIX threads."
	    # xlc_r has been known to produce buggy code in AIX 4.3.2.
	    # (e.g. pragma/overload core dumps)
	    # --jhi@iki.fi
	    cc=cc_r
            ;;
        '') 
	    cc=cc_r
            ;;
        *)
 	    cat >&4 <<EOM
For pthreads you should use the AIX C compiler cc_r.
(now your compiler was '$cc')
Cannot continue, aborting.
EOM
 	    exit 1
	    ;;
        esac

        # Add the POSIX threads library and the re-entrant libc.

        lddllibc="-lpthreads -lc_r"

        # Add the c_r library to the list of wanted libraries.
        # Make sure the c_r library is before the c library or
        # make will fail.
        set `echo X "$libswanted "| sed -e 's/ c / pthreads c_r /'`
        shift
        libswanted="$*"
	;;
esac

lddlflags="$lddlflags $lddllibc"

EOCBU
