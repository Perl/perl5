#! /bin/sh
# cygwin.sh - hints for building perl using the Cygwin environment for Win32
#
# Many of these inflexible settings should be changed to allow command-
# line overrides and allow for variations in local set-ups.
# I have made first guesses at some of these, but would welcome 
# corrections from someone actually using Cygwin.
#  Andy Dougherty  <doughera@lafayette.edu> Tue Sep 28 12:39:38 EDT 1999

_exe='.exe'
exe_ext='.exe'
# work around case-insensitive file names
firstmakefile='GNUmakefile'
sharpbang='#!'
startsh='#!/bin/sh'

archname='cygwin'
test -z "$cc" && cc='gcc'
libpth='/usr/i586-cygwin32/lib /usr/lib /usr/local/lib'
so='dll'
libs='-lcygwin -lm -lkernel32'
#optimize='-g'
# Is -I/usr/include *really* needed?
# Is -I/usr/local/include *really* needed?  I thought gcc always looked there.
ccflags="$ccflags -DCYGWIN -I/usr/include -I/usr/local/include"
# Is -L/usr/lib *really* needed?
ldflags="$ldflags -L/usr/i586-cygwin32/lib -L/usr/lib -L/usr/local/lib"
test -z "$usemymalloc" && usemymalloc='n'
dlsrc='dl_cygwin.xs'
cccdlflags=' '
ld='ld2'
# Is -L/usr/local/lib *really* needed?
lddlflags="$lddlflags -L/usr/local/lib"
useshrplib='true'
libperl='libperl.a'
dlext='dll'
dynamic_ext=' '

# What if they aren't using $prefix=/usr/local ??
# Why is this needed at all?  Doesn't Configure suggest this?
test -z "$man1dir" && man1dir=/usr/local/man/man1
test -z "$man3dir" && man3dir=/usr/local/man/man3

case "$ldlibpthname" in
'') ldlibpthname=PATH ;;
esac
