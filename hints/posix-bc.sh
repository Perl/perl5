#! /usr/bin/bash -norc
# hints/posix-bc.sh
#
# BS2000 (Posix Subsystem) hints by Thomas Dorner <Thomas.Dorner@start.de>
#
#  thanks to the authors of the os390.sh
#

# To get ANSI C, we need to use c89, and ld does not exist
cc='c89'
ld='c89'

# C-Flags:
ccflags='-K enum_long,llm_case_lower,llm_keep,no_integer_overflow -DPOSIX_BC -DUSE_PURE_BISON -D_XOPEN_SOURCE_EXTENDED'

# Flags on a RISC-Host (SUNRISE):
if [ -n "`bs2cmd SHOW-SYSTEM-INFO | egrep 'HSI-ATT.*TYPE.*SR'`" ]; then
    echo
    echo "Congratulations, you are running a machine with Sunrise CPUs."
    echo "Let's hope you have the matching RISC compiler as well."
    ccflags="-K risc_4000 $ccflags"
    ldflags='-K risc_4000'
fi

# Turning on optimization breaks perl (CORE-DUMP):
optimize='none'

# we don''t use dynamic memorys (yet):
so='none'
usedl='no'
dlext='none'

# On BS2000/Posix, libc.a does not really hold anything at all,
# so running nm on it is pretty useless.
usenm='no'

# other Options:

usemymalloc='no'

archobjs=ebcdic.o

