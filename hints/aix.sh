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
#    [(added support for socks) Jul 99 SOCKS support rewritten]
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

case "$usemymalloc" in
'')  usemymalloc='n' ;;
esac

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
dlext="o"

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
     *) ccflags="$ccflags -qmaxmem=16384" ;;
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
*gcc*) ccdlflags='-Xlinker' ;;
esac
# the required -bE:$installarchlib/CORE/perl.exp is added by
# libperl.U (Configure) later.

case "$ldlibpthname" in
'') ldlibpthname=LIBPATH ;;
esac

# The first 3 options would not be needed if dynamic libs. could be linked
# with the compiler instead of ld.
# -bI:$(PERL_INC)/perl.exp  Read the exported symbols from the perl binary
# -bE:$(BASEEXT).exp        Export these symbols.  This file contains only one
#                           symbol: boot_$(EXP)  can it be auto-generated?
case "$osvers" in
3*) 
    lddlflags="$lddlflags -H512 -T512 -bhalt:4 -bM:SRE -bI:$(PERL_INC)/perl.exp -bE:$(BASEEXT).exp -e _nostart -lc"
    ;;
*) 
    lddlflags="$lddlflags -bhalt:4 -bM:SRE -bI:$(PERL_INC)/perl.exp -bE:$(BASEEXT).exp -b noentry -lc"
    ;;
esac

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
	    if test ! -e /bin/cc_r; then
	 	    cat >&4 <<EOM
For pthreads you should use the AIX C compiler cc_r.
But I cannot find it in /bin.
Cannot continue, aborting.
EOM
	    fi
            ;;
        '') 
	    cc=cc_r
            ;;
        *)
 	    cat >&4 <<EOM
For pthreads you should use the AIX C compiler cc_r.
(now your compiler was set to '$cc')
Cannot continue, aborting.
EOM
 	    exit 1
	    ;;
        esac

        # Add the POSIX threads library and the re-entrant libc to lddflags.
        set `echo X "$lddlflags"| sed -e 's/ -lc$/ -lpthreads -lc_r/'`
        shift
        lddlflags="$*"

        # Add the POSIX threads library and the re-entrant libc to libswanted.
        # Make sure the c_r library is before the c library or
        # make will fail.
        set `echo X "$libswanted "| sed -e 's/ c / pthreads c_r /'`
        shift
        libswanted="$*"
	;;
esac
EOCBU

# This script UU/use64bits.cbu will get 'called-back' by Configure 
# after it has prompted the user for whether to use 64 bits.
cat > UU/use64bits.cbu <<'EOCBU'
case "$use64bits" in
$define|true|[yY]*)
	    case "`uname -r`" in
	    3.*|4.[012].*)
		cat >&4 <<EOM
AIX `uname -r` does not support 64-bit interfaces.
You should upgrade to at least AIX 4.3.
EOM
		exit 1
		;;
	    esac
	    ccflags="$ccflags `getconf XBS5_LPBIG_OFFBIG_CFLAGS`"
    	    ccflags="$ccflags -DUSE_LONG_LONG"

	    ldflags="$ldflags `getconf XBS5_LPBIG_OFFBIG_LDFLAGS`"
	    # _Somehow_ in AIX 4.3.1.0 the above getconf call manages to
	    # insert(?) *something* to $ldflags so that later (in Configure) evaluating
	    # $ldflags causes a newline after the '-b64' (the result of the getconf).
	    # Try it out: just uncomment the below line and rerun Configure:
#	    echo >& "AIX $ldflags mystery" ; exit 1
	    # Just don't ask me how AIX does it.
	    # Therefore the line re-evaluating ldflags: it seems to drop the whatever
	    # AIX managed to break. --jhi
	    ldflags="`echo $ldflags`"

	    libswanted="$libswanted `getconf XBS5_LPBIG_OFFBIG_LIBS|sed -e 's@^-l@@' -e 's@ -l@ @g'`"
	    # When a 64-bit cc becomes available $archname64
	    # may need setting so that $archname gets it attached.
	    ;;
esac
EOCBU

# EOF
