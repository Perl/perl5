# hints/os390.sh <-- keep the # character here
#
# OS/390 hints by David J. Fiander <davidf@mks.com>
#
# OS/390 OpenEdition Release 3 Mon Sep 22 1997 thanks to:
#
#     John Goodyear <johngood@us.ibm.com>
#     John Pfuntner <pfuntner@vnet.ibm.com>
#     Len Johnson <lenjay@ibm.net>
#     Bud Huff  <BAHUFF@us.oracle.com>
#     Peter Prymmer <pvhp@forte.com>
#     Andy Dougherty  <doughera@lafayette.edu>
#     Tim Bunce  <Tim.Bunce@ig.co.uk>
#
#  as well as the authors of the aix.sh file
#
# z/OS 2.4 Support added thanks to:
#     Mike Fulton
#     Karl Williamson
#     Igor Todorovsky

me=$0

# Prepend your favorites with Configure -Aprepend:ccflags="your favorites"
#                                       -Aprepend:cppflags="your favourites"
# No others get prepended, so for example, passing in a non-empty ldflags
# overrides anything set here.

archobjs="os390.o"

# This doesn't change the value in Configure, but for now is good enough for
# the rest of this file.  The correct value would be
#  os390_ver=$(uname -Iv).$(uname -Ir)"
os390_ver=$(uname -Iv)

def_os390_cccdlflags=""
def_os390_ccflags=""
def_os390_cppflags=""
def_os390_defs=""
def_os390_ldflags=""

# We now require C99
def_os390_ccflags="$def_os390_ccflags -std=c99"

# Certain extensions to z/OS library functions and extra library functions are
# available only when this is defined.  For example, to enable "unicode literals"
def_os390_ccflags="$def_os390_ccflags -D_EXT=1"

# Export all externally defined functions and variables in the compilation
# unit so that a DLL application can use them. 'default' really should be named
# 'public'
def_os390_ccflags="$def_os390_ccflags -fvisibility=default"

# Use the behaviors for various library functions specified by POSIX 2008.
def_os390_ccflags="$def_os390_ccflags -D_POSIX_C_SOURCE=200809L"

# Various values that we need are not available unless this is set
def_os390_ccflags="$def_os390_ccflags -D_XPLATFORM_SOURCE=1";

# For #ifdefs in code to mark this as z/OS.  OEMVS is a synonym for __MVS__
def_os390_defs="$def_os390_defs -DOS390 -DZOS -DOEMVS";

# Turn on POSIX compatibility modes
#  https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.bpxbd00/ftms.htm
def_os390_defs="$def_os390_defs -D_ALL_SOURCE";

case "$use64bitall" in
'undef') echo "32-bit compilation not currently supported" >&4
    # Though it could easily be added.  IBM says no such hardware now exists
    exit 1;
  ;;
*)
  case "$cc" in
  '') cc='clang' ;;
  esac
  case "$ld" in
  '') ld='clang' ;;
  esac
  def_os390_ccflags="$def_os390_ccflags -m64"
  def_os390_ldflags="$def_os390_ldflags -m64"
  ;;
esac

# Help 'make' find os390.c
test -h os390.c || ln -s os390/os390.c os390.c

myfirstchar=$(od -A n -N 1 -t x $me | xargs | tr [:lower:] [:upper:] | tr -d 0)
if [ "${myfirstchar}" = "23" ]; then # 23 is '#' in ASCII
  unset ebcdic
  def_os390_ccflags="$def_os390_ccflags -fzos-le-char-mode=ascii"

  # Enhanced ASCII support provides the ability to convert between ASCII and
  # EBCDIC
  def_os390_defs="$def_os390_defs -D_ENHANCED_ASCII_EXT=0xFFFFFFFF"

  # Allows ability to have bimodal ASCII/EBCDIC support
  def_os390_defs="$def_os390_defs -D_AE_BIMODAL=1"

  # zopen wants @INC entries relocated at runtime based on the path to the perl
  # binary
  case "$userelocatableinc" in
    '') userelocatableinc="define" ;;
  esac

  # Find perl base on PATH environment variable rather than hardcoding install
  # location
  startperl='#!/bin/env perl'
else
  ebcdic=true
  def_os390_ccflags="$def_os390_ccflags -fzos-le-char-mode=ebcdic"
  def_os390_ccflags="$def_os390_ccflags -fexec-charset=IBM-1047"
fi

# ensure that the OS/390 yacc generated parser is reentrant.
def_os390_defs="$def_os390_defs -DYYDYNAMIC";

# LC_MESSAGES only affects the yes/no strings in langinfo; not the things we
# expect it to
def_os390_defs="$def_os390_defs -DNO_LOCALE_MESSAGES"

# Set up feature test macros required for features available on supported z/OS
# systems
def_os390_defs="$def_os390_defs -D_OPEN_THREADS=3"
def_os390_defs="$def_os390_defs -D_UNIX03_SOURCE=1"
def_os390_defs="$def_os390_defs -D_OPEN_SYS_FILE_EXT=1"
def_os390_defs="$def_os390_defs -D_OPEN_SYS_SOCK_IPV6"
def_os390_defs="$def_os390_defs -D_XOPEN_SOURCE=600"
def_os390_defs="$def_os390_defs -D_XOPEN_SOURCE_EXTENDED"

# These seem to work as of version 3.1, but didn't use to.  It's unknown when
# they started to work.  khw thinks it was 2.5-ish, so didn't bother adding a
# check for 3.1 vs 3.0
if [ "$os390_ver" -lt 3 ]; then
    d_gethostbyname_r='undef'
    d_gethostent_r='undef'

    # maximum signal number; not furnished by IBM
    def_os390_defs="$def_os390_defs -DMAXSIG=39 -DNSIG=39";

    # Configure says this exists, but it doesn't work properly.  See
    # <54DCE073.4010100@khwilliamson.com>
    d_dir_dd_fd='undef'

    # Turning on optimization causes perl to not even compile from miniperl.
    # You can override this with Configure -Doptimize='-O2' or somesuch.
    case "$optimize" in
      '') optimize=' ' ;;
    esac
fi

# Some header files on z/OS have trigraphs in them that clang doesn't handle
# without this option.
def_os390_cppflags="$def_os390_cppflags -trigraphs"

# Suppress the trigraph warnings, and some headers have pragmas that clang
# isn't familiar with
def_os390_ccflags="$def_os390_ccflags -Wno-trigraphs -Wno-unknown-pragmas"

# Time to set the external 'cppflags'
cppflags="$cppflags $def_os390_cppflags"

# Combine -D with cflags
ccflags="$ccflags $def_os390_ccflags $cppflags $def_os390_defs"

case "$so" in
'') so='a' ;;
esac

case "$alignbytes" in
'') alignbytes=8 ;;
esac

case "$usemymalloc" in
'') usemymalloc='n' ;;
esac

# On OS/390, libc.a doesn't really hold anything at all,
# so running nm on it is pretty useless.
# You can override this with Configure -Dusenm.
case "$usenm" in
'') usenm='false' ;;
esac

case "$ldflags" in
'') ldflags="$def_os390_ldflags";;
esac

# msf symbol information is now in NOLOAD section and so, while on disk,
# does not require time to load but is useful in problem determination if
# required, so it is no longer necessary to link with -Wl,EDIT=NO

# In order to build with dynamic be sure to specify:
#   Configure -Dusedl
# Do not forget to add $archlibexp/CORE to your LIBPATH, e.g. blead/perl5
# You might want to override some of this with things like:
#  Configure -Dusedl -Ddlext=so -Ddlsrc=dl_dllload.xs.
case "$usedl" in
'undef')
   usedl='n'
   case "$dlext" in
   '') dlext='none' ;;
   esac
   ;;
*)
   case "$useshrplib" in
   '') useshrplib='true' ;;
   esac
   case "$dlsrc" in
   '') dlsrc='dl_dllload.xs' ;;
   esac
   so='so'
   case "$dlext" in
     '') dlext='so' ;;
   esac
   libperl="libperl.$so"

   # Allows char **environ to be accessed from a dynamically loaded
   # module such as a DLL
   ccflags="$ccflags -D_SHR_ENVIRON"

   case "$def_os390_cccdlflags" in
     '') lddlflags="-m64" # Revert this after merging
                          # https://github.com/Perl/perl5/pull/24465
        ;;
     *) cccdlflags="-c $def_os390_cccdlflags"
        lddlflags="$def_os390_cccdlflags"
        ;;
   esac

   # The following will need to be modified for the installed libperl.x.
   # The modification to Config.pm is done by the installperl script after the
   # build and test.  These are written to a CBU so that the libperl.x file
   # comes after all the dash-options in the flags.  Configure takes the
   # lddlflags we give it and looks for paths to libraries to append -L options
   # to lddlflags.  But this causes the file libperl.x to appear in the final
   # command line after the -L options.  And z/OS doesn't like filenames after
   # options.  This CBU defers the adding of libperl.x until after any munging
   # that Configure does.
   cat >config.arch <<'	EOCBU'
	case "ccdlflags" in
	'') ccdlflags="`pwd`/libperl.x" ;;
	 *) ccdlflags="$ccdlflags `pwd`/libperl.x" ;;
	esac
	lddlflags="$lddlflags `pwd`/libperl.x"
	EOCBU
   ;;
esac

# even on static builds using LIBPATH should be OK.
case "$ldlibpthname" in
'') ldlibpthname=LIBPATH ;;
esac

# The following should always be used.  Not doing this causes compilation
# errors in 3.1, and presumably earlier, with different function signatures
# than perl expects.
d_oldpthreads='define'

# Header files to include.
# You can override these with Configure -Ui_time -Ui_systime -Dd_pthread_atfork.
case "$i_time" in
'') i_time='define' ;;
esac
case "$i_systime" in
'') i_systime='define' ;;
esac

# Untested if this still is needed
case "$d_pthread_atfork" in
'') d_pthread_atfork='undef' ;;
esac

# (from aix.sh)
# uname -m output is too specific and not appropriate here
# osname should come from Configure
# You can override this with Configure -Darchname='s390' but please don't.
case "$archname" in
'') archname="$osname" ;;
esac

# In ASCII mode, if this is used, it causes generating some Makefiles to fail
# due to EBCDIC being generated.  Pod-Checker is one.  It appears to work in
# EBCDIC mode, but turning off anyway to be safe.
case "$d_pipe2" in
'') d_pipe2='undef' ;;
esac

# Configure's compilation of shm.h that is supposed to show if that file
# includes a prototype definition currently results in garbage (reason unknown,
# but maybe it's the same one as pipe2() not working) so the grep fails.
case "$d_shmatprototype" in
'') d_shmatprototype='define' ;;
esac

# z/OS sets this to either 0 or the illegal 0x500010DBE8.  So, say it's
# unvavailable.
case "$d_tm_tm_gmtoff" in
'') d_tm_tm_gmtoff='undef' ;;
esac

# z/OS has these elements in 'struct stat', but often (maybe always) sets them
# each to -1, an illegal value.
case "$d_statblks" in
'') d_statblks='undef' ;;
esac

# Note that Makefile.SH employs a bare yacc command to generate
# perly.[hc], hence you may wish to:
#
#    alias yacc='myyacc'
#
# Then if you would like to use myyacc and skip past the
# following warnings try invoking Configure like so:
#
#    sh Configure -Dbyacc=yacc
#
# This trick ought to work even if your yacc is byacc.
#
# msf - need to check but I think /etc/yyparse.c is always around now
if test "X$byacc" = "Xbyacc" ; then
   if test -e /etc/yyparse.c ; then
       : we should be OK - perhaps do a test -r?
   else
       cat <<EOWARN >&4

Warning.  You do not have a copy of yyparse.c, the default
yacc parser template file, in place in /etc.
EOWARN
       if test -e /samples/yyparse.c ; then
           cat <<EOWARN >&4

There does appear to be a template file in /samples though.
Please run:

     cp /samples/yyparse.c /etc

before attempting to Configure the build of $package.

EOWARN
       else
           cat <<EOWARN >&4

There does not appear to be one in /samples either.
If you feel you can make use of an alternate yacc-like
parser generator then please read the comments in the
hints/os390.sh file carefully.

EOWARN
       fi
       exit 1
   fi
fi

# Doesn't find the prototype
case "d_gethostbyaddr" in
  "") d_gethostbyaddr_r='undef'
  ;;
esac

# nan() used to not work as expected: nan("") or nan("0") returned zero, not a
# nan.  This may have been a C89 issue.
# http://www-01.ibm.com/support/knowledgecenter/SSLTBW_1.12.0/com.ibm.zos.r12.bpxbd00/nan.htm%23nan?lang=en
#d_nan='undef'

############################################################################
# Thread support
# use Configure -Dusethreads to enable
# This script UU/usethreads.cbu will get 'called-back' by Configure
# after it has prompted the user for whether to use threads.
# setlocale() returns NULL if a thread has been created, so we can't use it
# generally.  (It would be possible to have it work for initialization, so that
# the user could specify a locale for the whole program; but deferring doing
# that work until someone wants it)  Maybe IBM will support POSIX 2008 at some
# point.  There are hooks that make it look like they were working on it.
cat > UU/usethreads.cbu <<'EOCBU'
case "$usethreads" in
$define|true|[yY]*)
   echo "Your system's setlocale() is broken under threads; marking it as unavailable" >&4
   d_setlocale="undef"
   d_setlocale_accepts_any_locale_name="undef"
   d_has_C_UTF8="false"
;;
esac
EOCBU
