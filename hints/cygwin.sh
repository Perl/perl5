#! /bin/sh
# cygwin32.sh - hintsfile for building perl on Windows NT using the
#     Cygnus Win32 Development Kit.
#

_exe='.exe'
exe_ext='.exe'
# work around case-insensitive file names
firstmakefile='GNUmakefile'
sharpbang='#!'
startsh='#!/bin/sh'

archname='cygwin32'
cc='gcc'
libpth='/usr/i586-cygwin32/lib /usr/lib /usr/local/lib'
so='dll'
libs='-lcygwin -lm -lkernel32'
#optimize='-g'
ccflags='-DCYGWIN32 -I/usr/include -I/usr/local/include'
ldflags='-L/usr/i586-cygwin32/lib -L/usr/lib -L/usr/local/lib'
usemymalloc='n'
dlsrc='dl_cygwin32.xs'
cccdlflags=' '
ld='ld2'
lddlflags='-L/usr/local/lib'
useshrplib='true'
libperl='libperl.a'
dlext='dll'

man1dir=/usr/local/man/man1
man3dir=/usr/local/man/man3
sitelib=/usr/local/lib/perl5/site_perl

case "$ldlibpthname" in
'') ldlibpthname=PATH ;;
esac
