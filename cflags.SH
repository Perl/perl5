#!/bin/sh

# Generate the cflags script, which is used to determine what cflags
# to pass to the compiler for compiling the core perl.
#
# This does NOT affect the XS compilation (ext, dist, cpan)
# since that uses %Config values directly.
#
# For example, since -Wall adds -Wunused-*, a bare -Wall (without
# amending that with -Wno-unused-..., or with the PERL_UNUSED_...)
# would be too much for XS code because there are too many generated
# but often unused things.
#
# We create a temporary test C program and repeatedly compile it with
# various candidate flags, and from the compiler output, determine what
# flags are supported.
#
# From this we initialise the following variables in the cflags script:
#
#   $myccflags (possibly edited version of $Config{ccflags})
#   $warn
#   $stdflags
#   $extra
#   $_exe

case $PERL_CONFIG_SH in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
# This forces SH files to create target in same directory as SH file.
# This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

if test -f config_h.SH -a ! -f config.h; then
    . ./config_h.SH
    CONFIG_H=already-done
fi

warn=''

# Add -Wall for the core modules iff gcc and not already -Wall
case "$gccversion" in
'') ;;
Intel*) ;; # The Intel C++ plays gcc on TV but is not really it.
*)  case "$ccflags" in
    *-Wall*) ;;
    *) warn="$warn -Wall" ;;
    esac
    ;;
esac

# Create a test source file for testing what options can be fed to
# gcc in this system; include a selection of most common and commonly
# hairy include files.

cat >_cflags.c <<__EOT__
#include "EXTERN.h"
#include "perl.h"
/* The stdio.h, errno.h, and setjmp.h should be there in any ANSI C89. */
#include <stdio.h>
#include <errno.h>
#include <setjmp.h>
/* Just in case the inclusion of perl.h did not
 * pull in enough system headers, let's try again. */
#ifdef I_STDLIB
#include <stdlib.h>
#endif
#ifdef I_STDDEF
#include <stddef.h>
#endif
#ifdef I_STDARG
#include <stdarg.h>
#endif
#ifdef I_LIMITS
#include <limits.h>
#endif
#ifdef I_DIRENT
#include <dirent.h>
#endif
#ifdef I_UNISTD
#include <unistd.h>
#endif
#ifdef I_SYS_TYPES
#include <sys/types.h>
#endif
#ifdef I_SYS_PARAM
#include <sys/param.h>
#endif
#ifdef I_SYS_RESOURCE
#include <sys/resource.h>
#endif
#ifdef I_SYS_SELECT
#include <sys/select.h>
#endif
#if defined(HAS_SOCKET) && !defined(VMS) && !defined(WIN32) /* See perl.h. */
#include <sys/socket.h>
#endif
#ifdef I_SYS_STAT
#include <sys/stat.h>
#endif
#ifdef I_SYS_TIME
#include <sys/time.h>
#endif
#ifdef I_SYS_TIMES
#include <sys/times.h>
#endif
#ifdef I_SYS_WAIT
#include <sys/wait.h>
#endif
/* The gcc -ansi can cause a lot of noise in Solaris because of:
 /usr/include/sys/resource.h:148: warning: 'struct rlimit64' declared inside parameter list
 */
int main(int argc, char *argv[]) {

/* Add here test code found to be problematic in some gcc platform. */

/* Off_t/off_t is a struct in Solaris with largefiles, and with gcc -ansi
 * that struct cannot be compared in some gcc releases with a flat
 * integer, such as a STRLEN. */

  IV iv;
  Off_t t0a = 2;
  STRLEN t0b = 3;
  int t0c = t0a == t0b;

/* In FreeBSD 6.2 (and probably other releases too), with -Duse64bitint,
   perl will use atoll(3).  However, that declaration is hidden in <stdlib.h>
   if we force the compiler to use -std=c89 mode.
*/
  iv = Atol("42");

  return (!t0c && (iv == 42)) ? 0 : -1; /* Try to avoid 'unused' warnings. */
}
__EOT__

stdflags=''

# Further gcc warning options.  Build up a list of options that work.
# Note that some problems may only show up with combinations of options,
# e.g. a warning might show up only with -Wall -ansi, not with either
# one individually.
# TODO:  Ponder whether to migrate this back to Configure so hints files can
# tweak it.  Also, be paranoid about whether results we've deduced in Configure
# (especially about things like long long, which are not in C89) will still be
# valid if we now add flags like -std=c89.

case "$gccversion" in
'') ;;
[12]*) ;; # gcc versions 1 (gasp!) and 2 are not good for this.
Intel*) ;; # # Is that you, Intel C++?
# XXX if -pedantic (or -pedantic-errors!) is ever added,
# the -Werror=declaration-after-statement can be removed
# since -std=c89 -pedantic implies the -Werror=...
*)  for opt in -ansi -std=c89 -Wextra -W \
		-Werror=declaration-after-statement \
		-Wc++-compat -Wwrite-strings
    do
       case " $ccflags " in
       *" $opt "*) ;; # Skip if already there.
       *) rm -f _cflags$_exe
          case "`$cc -DPERL_NO_INLINE_FUNCTIONS $ccflags $warn $stdflags $opt _cflags.c -o _cflags$_exe 2>&1`" in
          *"unrecognized"*) ;;
          *"unknown"*) ;;
          *"implicit declaration"*) ;; # Was something useful hidden?
          *"Invalid"*) ;;
          *"is valid for C"*) ;;
          *) if test -x _cflags$_exe
             then
               case "$opt" in
               -std*) stdflags="$stdflags $opt" ;;
               *) case "$opt" in
                  -W)
                    # -Wextra is the modern form of -W, so add
                    # -W only if -Wextra is not there already.
                    case " $warn " in
                    *-Wextra*) ;;
                    *) warn="$warn opt" ;;
                    esac
                    ;;
                  *) warn="$warn $opt" ;;
                  esac
               esac
             fi
             ;;
          esac
          ;;
       esac
    done
    ;;
esac
rm -f _cflags.c _cflags$_exe

case "$gccversion" in
'') ;;
*)
  if [ "$gccansipedantic" = "" ]; then
    # If we have -Duse64bitint (or equivalent) in effect and the quadtype
    # has become 'long long', gcc -pedantic becomes unbearable (moreso
    # when combined with -Wall) because long long and LL and %lld|%Ld
    # become warn-worthy.  So let's drop the -pedantic in that case.
    case "$quadtype:$sPRId64" in
    "long long"*|*lld*|*Ld*)
      echo "cflags.SH: Removing -pedantic and warn because of quadtype='long long'."
      ccflags="`echo $ccflags|sed 's/-pedantic/ /'`"
      warn="`echo $warn|sed 's/-pedantic/ /'`"
      ;;
    esac
    # Similarly, since 'long long' isn't part of C89, FreeBSD 6.2 headers
    # don't declare atoll() under -std=c89, but we need it.  In general,
    # insisting on -std=c89 is inconsistent with insisting on using
    # 'long long'. So drop -std=c89 and -ansi as well if we're using
    # 'long long' as our main integral type.
    case "$ivtype" in
    "long long")
        echo "cflags.SH: Removing -pedantic, -std=c89, and -ansi because of ivtype='long long'."
	ccflags=`echo $ccflags|sed -e 's/-pedantic/ /' -e 's/-std=c89/ /' -e 's/-ansi/ /'`
	warn=`echo $warn|sed -e 's/-pedantic/ /' -e 's/-ansi/ /'`
	stdflags=`echo $stdflags|sed -e 's/-std=c89/ /'`
	;;
    esac
  fi
  # Using certain features (like the gcc statement expressions)
  # requires knowing whether -pedantic has been specified.
  case "$warn$ccflags" in
  *-pedantic*)
    echo "cflags.SH: Adding -DPERL_PEDANTIC because of -pedantic."
    warn="$warn -DPERL_GCC_PEDANTIC"
    ;;
  esac
  ;;
esac

case "$cc" in
*g++*)
  # Extra paranoia in case people have bad canned ccflags:
  # bad in the sense that the flags are accepted by g++,
  # but then whined about.
  #
  # -Werror=d-a-s option is valid for g++, by definition,
  # but we remove it just for cleanliness and shorter command lines.
  for f in -Wdeclaration-after-statement \
		-Werror=declaration-after-statement \
		-std=c89
  do
    case "$ccflags" in
    *"$f"*)
      echo "cflags.SH: Removing $ccflags because of g++."
      ccflags=`echo $ccflags|sed 's/$f/ /'` ;;
    esac
  done
  ;;
esac

for f in -Wdeclaration-after-statement -Werror=declaration-after-statement
do
  case "$cppflags" in
  *"$f"*)
    echo "cflags.SH: Removing $f from cppflags."
    cppflags=`echo $cppflags|sed 's/$f/ /'` ;;
  esac
done

# Code to set any extra flags here.
extra=''

echo "Extracting cflags (with variable substitutions)"
# This section of the file will have variable substitutions done on it.
# Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
# Protect any dollar signs and backticks that you do not want interpreted
# by putting a backslash in front.  You may delete these comments.
rm -f cflags
$spitshell >cflags <<!GROK!THIS!
$startsh

# !!!!!!!   DO NOT EDIT THIS FILE   !!!!!!!

# This file is generated by cflags.SH

# Used to restore possible edits by cflags.SH.
myccflags="$ccflags"
# Extra warnings, used e.g. for gcc.
warn="$warn"
# Extra standardness.
stdflags="$stdflags"
# Extra extra.
extra="$extra"
# what do executables look like?
_exe="$_exe"

!GROK!THIS!

# In the following dollars and backticks do not need the extra backslash.
$spitshell >>cflags <<'!NO!SUBS!'
case $PERL_CONFIG_SH in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
        ccflags="$myccflags"  # Restore possible edits by cflags.SH.
	;;
esac

# syntax: cflags [optimize=XXX] [file[.suffix]] ...
#   displays the proposed compiler command line for each 'file'
#
#   with no file, dispalys it for all *.c files.
#   The optimise=XXX arg (if present) is evalled, setting the default
#   value of the $optimise variable, which is output on the command line
#   (but which may be overridden for specific files below)

case "X$1" in
Xoptimize=*|X"optimize=*")
	eval "$1"
	shift
	;;
esac

case $# in
0) set *.c; echo "The current C flags are:" ;;
esac

set `echo "$* " | sed -e 's/\.[oc] / /g' -e 's/\.obj / /g' -e "s/\\$obj_ext / /g"`

for file do

    case "$#" in
    1) ;;
    *) echo $n "    $file.c	$c" ;;
    esac

    # allow variables like toke_cflags to be evaluated

    if echo $file | grep -v / >/dev/null
    then
      eval 'eval ${'"${file}_cflags"'-""}'
    fi

    # or customize here

    case "$file" in
    *) ;;

    # Customization examples follow.
    #
    # The examples are intentionally unreachable as the '*)' case above always
    # matches. To use them, move before the '*)' and edit as appropriate.
    # It is not a good idea to set ccflags to an absolute value here, as it
    # often contains general -D defines which are needed for correct
    # compilation. It is better to edit ccflags as shown, using interpolation
    # to add flags, or sed to remove flags.

    av) ccflags=`echo $ccflags | sed -e s/-pipe//` ;;
    deb) ccflags="$ccflags -fno-jump-tables" ;;
    hv) warn=`echo $warn | sed -e s/-Wextra//` ;;
    toke) optimize=-O0 ;;
    esac

    # Can we perhaps use $ansi2knr here
    echo "$cc -c -DPERL_CORE $ccflags $stdflags $optimize $warn $extra"

    . $TOP/config.sh

    # end per file behaviour
done
!NO!SUBS!
chmod 755 cflags
$eunicefix cflags
