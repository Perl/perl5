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
libpth='/cygnus/cygwin-b20/H-i586-cygwin32/i586-cygwin32/lib /usr/local/lib'
so='dll'
libs='-lcygwin -lm -lc -lkernel32'
#optimize='-g'
ccflags='-DCYGWIN32'
ldflags='-L. -L/usr/local/lib'
usemymalloc='n'
dlsrc='dl_cygwin32.xs'
cccdlflags=' '
ld='ld2'
lddlflags='--export-dynamic -L. -L/usr/local/lib'
useshrplib='true'
libperl='libperl.a'
dlext='dll'

man1dir=/usr/local/man/man1
man3dir=/usr/local/man/man3
sitelib=/usr/local/lib/perl5/site_perl
