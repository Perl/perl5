#! /bin/sh
# cygwin.sh - hints for building perl using the Cygwin environment for Win32
#

# not otherwise settable
exe_ext='.exe'
firstmakefile='GNUmakefile'
case "$ldlibpthname" in
'') ldlibpthname=PATH ;;
esac

# mandatory (overrides defaults)
test -z "$cc" && cc='gcc'
if test -z "$libpth"
then
    libpth=`gcc -print-file-name=libc.a`
    libpth=`dirname $libpth`
    libpth=`cd $libpth && pwd`
fi
so='dll'
libs='-lcygwin -lm -lkernel32'
ccflags="$ccflags -DCYGWIN"
archname='cygwin'
cccdlflags=' '
ld='ld2'

# optional(ish)
# - perl malloc needs to be unpolluted
bincompat5005='undef'
# - build shared libperl.dll
useshrplib='true'
libperl='libperl.a'

# strip exe's and dll's
#ldflags="$ldflags -s"
#ccdlflags="$ccdlflags -s"
#lddlflags="$lddlflags -s"
