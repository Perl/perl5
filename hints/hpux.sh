# hints/hpux.sh
# Perl Configure hints file for Hewlett Packard HP/UX 9.x and 10.x
# This file is based on 
# hints/hpux_9.sh, Perl Configure hints file for Hewlett Packard HP/UX 9.x
# Use Configure -Dcc=gcc to use gcc.
# From: Jeff Okamoto <okamoto@hpcc123.corp.hp.com>
# Date: Thu, 28 Sep 95 11:06:07 PDT
# and
# hints/hpux_10.sh, Perl Configure hints file for Hewlett Packard HP/UX 10.x
# From: Giles Lean <giles@nemeton.com.au>
# Date: Tue, 27 Jun 1995 08:17:45 +1000

# Use Configure -Dcc=gcc to use gcc.
# Use Configure -Dprefix=/usr/local to install in /usr/local.

# Turn on the _HPUX_SOURCE flag to get many of the HP add-ons
ccflags="$ccflags -D_HPUX_SOURCE"
ldflags="$ldflags"

# Check if you're using the bundled C compiler.  This compiler doesn't support
# ANSI C (the -Aa flag) nor can it produce shared libraries.  Thus we have
# to turn off dynamic loading.
case "$cc" in
'') if cc $ccflags -Aa 2>&1 | $contains 'Unknown option "A"' >/dev/null
    then
	case "$usedl" in
	 '') usedl="$undef"
	     cat <<'EOM'

The bundled C compiler can not produce shared libraries, so you will
not be able to use dynamic loading. 

EOM
	     ;;
	esac
    else
	ccflags="$ccflags -Aa"	# The add-on compiler supports ANSI C
    fi
    optimize='-O'
    ;;
esac

# Remove bad libraries that will cause problems
# (This doesn't remove libraries that don't actually exist)
# -lld is unneeded (and I can't figure out what it's used for anyway)
# -ldbm is obsolete and should not be used
# -lBSD contains BSD-style duplicates of SVR4 routines that cause confusion
# -lPW is obsolete and should not be used
# Although -lndbm should be included, it will make perl blow up if you should
# copy the binary to a system without libndbm.sl.
# The libraries crypt, malloc, ndir, and net are empty.
set `echo " $libswanted " | sed -e 's@ ndbm @ @' -e 's@ ld @ @' -e 's@ dbm @ @' -e 's@ BSD @ @' -e 's@ PW @ @'`
libswanted="$*"

# If you copy the perl binaries to other systems and the dynamic loader
# complains about missing libraries, you can either copy the shared libraries
# or switch the comments to recompile perl to use archive libraries
# ccdlflags="-Wl,-E -Wl,-a,archive $ccdlflags"
ccdlflags="-Wl,-E $ccdlflags"

usemymalloc='y'
alignbytes=8
selecttype='int *' 

# There are some lingering issues about whether g/setpgrp should be a part
# of the perl core.  This setting should cause perl to conform to the Principle
# of Least Astonishment.  The best thing is to use the g/setpgrp in the POSIX
# module.
d_bsdpgrp='define'

# If your compile complains about FLT_MIN, uncomment the next line
# POSIX_cflags='ccflags="$ccflags -DFLT_MIN=1.17549435E-38"'

# Comment these out if you don't want to follow the SVR4 filesystem layout
# that HP-UX 10.0 uses
case "$prefix" in
'') prefix='/opt/perl5'
    privlib='/opt/perl5/lib'
    archlib='/opt/perl5/lib/hpux'
    man3dir='/opt/perl5/man/man3'
    ;;
esac

