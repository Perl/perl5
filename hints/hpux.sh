# hints/hpux.sh
# Perl Configure hints file for Hewlett Packard HP-UX 9.x and 10.x
# This file is based on 
# hints/hpux_9.sh, Perl Configure hints file for Hewlett Packard HP-UX 9.x
# Use Configure -Dcc=gcc to use gcc.
# From: Jeff Okamoto <okamoto@corp.hp.com>
# and
# hints/hpux_10.sh, Perl Configure hints file for Hewlett Packard HP-UX 10.x
# From: Giles Lean <giles@nemeton.com.au>

# This version: December 27, 1996
# Current maintainer: Jeff Okamoto <okamoto@corp.hp.com>

# Use Configure -Dcc=gcc to use gcc.
# Use Configure -Dprefix=/usr/local to install in /usr/local.

# Some users have reported problems with dynamic loading if the 
# environment variable LDOPTS='-a archive' .

# Turn on the _HPUX_SOURCE flag to get many of the HP add-ons
ccflags="$ccflags -D_HPUX_SOURCE"

# If you plan to use gcc, then you should uncomment the following line
# so you get the HP math library and not the GCC math library.
# ccflags="$ccflags -L/lib/pa1.1"

# Check if you're using the bundled C compiler.  This compiler doesn't support
# ANSI C (the -Aa flag) nor can it produce shared libraries.  Thus we have
# to turn off dynamic loading.
case "$cc" in
'') if cc $ccflags -Aa 2>&1 | $contains 'option' >/dev/null
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

# Determine the architecture type of this system.
xxuname=`uname -r`
if echo $xxuname | $contains '10'
then
	# This system is running 10.0
	xxcpu1=`getconf CPU_VERSION`
	xxcpu2=`printf %#x ${xxcpu1}`
	xxcontext=`grep "$xxcpu2" /usr/include/sys/unistd.h`
	if echo "$xxcontext" | $contains 'PA-RISC1.1'
	then
		archname='PA-RISC1.1'
	elif echo "$xxcontext" | $contains 'PA-RISC1.0'
	then
		archname='PA-RISC1.0'
	elif echo "$xxcontext" | $contains 'PA-RISC2'
	then
		archname='PA-RISC2'
	else
		echo "This 10.0 system is of a PA-RISC type I don't recognize."
		echo "Debugging output: $xxcontext"
		archname=''
	fi
else
	# This system is not running 10.0
	xxcontext=`/bin/getcontext`
	if echo "$xxcontext" | $contains 'PA-RISC1.1'
	then
		archname='PA-RISC1.1'
	elif echo "$xxcontext" | $contains 'PA-RISC1.0'
	then
		archname='PA-RISC1.0'
	elif echo "$xxcontext" | $contains 'HP-MC'
	then
		archname='HP-MC68K'
	else
		echo "I cannot recognize what chip set this system is using."
		echo "Debugging output: $xxcontext"
		archname=''
	fi
fi

# Remove bad libraries that will cause problems
# (This doesn't remove libraries that don't actually exist)
# -lld is unneeded (and I can't figure out what it's used for anyway)
# -ldbm is obsolete and should not be used
# -lBSD contains BSD-style duplicates of SVR4 routines that cause confusion
# -lPW is obsolete and should not be used
# The libraries crypt, malloc, ndir, and net are empty.
# Although -lndbm should be included, it will make perl blow up if you should
# copy the binary to a system without libndbm.sl.  See ccdlflags below.
set `echo " $libswanted " | sed  -e 's@ ld @ @' -e 's@ dbm @ @' -e 's@ BSD @ @' -e 's@ PW @ @'`
libswanted="$*"

# By setting the deferred flag below, this means that if you run perl on a
# system that does not have the required shared library that you linked it
# with, it will die when you try to access a symbol in the (missing) shared
# library.  If you would rather know at perl startup time that you are
# missing an important shared library, switch the comments so that immediate,
# rather than deferred loading is performed.
# ccdlflags="-Wl,-E $ccdlflags"
ccdlflags="-Wl,-E -Wl,-B,deferred $ccdlflags"

usemymalloc='y'
alignbytes=8
selecttype='int *'

# If your compile complains about FLT_MIN, uncomment the next line
# POSIX_cflags='ccflags="$ccflags -DFLT_MIN=1.17549435E-38"'

# Comment this out if you don't want to follow the SVR4 filesystem layout
# that HP-UX 10.0 uses
case "$prefix" in
'') prefix='/opt/perl5.003' ;;
esac

# Date: Fri, 6 Sep 96 23:15:31 CDT
# From: "Daniel S. Lewart" <d-lewart@uiuc.edu>
# I looked through the gcc.info and found this:
#   * GNU CC compiled code sometimes emits warnings from the HP-UX
#     assembler of the form:
#          (warning) Use of GR3 when frame >= 8192 may cause conflict.
#     These warnings are harmless and can be safely ignored.
