#! /usr/bin/bash -norc
# hints/posix-bc.sh
#
# BS2000 (Posix Subsystem) hints by Thomas Dorner <Thomas.Dorner@start.de>
#
#  thanks to the authors of the os390.sh
#

# To get ANSI C, we need to use c89, and ld doesn't exist
cc='c89'
ld='c89'

# C-Flags:
ccflags='-DPOSIX_BC -DUSE_PURE_BISON -D_XOPEN_SOURCE_EXTENDED'

# Turning on optimization breaks perl (CORE-DUMP):
optimize='none'

# we don''t use dynamic memorys (yet):
so='none'
usedl='no'
dlext='none'

# On BS2000/Posix, libc.a doesn't really hold anything at all,
# so running nm on it is pretty useless.
usenm='no'

# other Options:

usemymalloc='no'

archobjs=ebcdic.o

