# BeOS hints file
# $Id: beos.sh,v 1.1 1998/02/16 03:51:45 dogcow Exp $

if [ ! -f ../beos/nm ]; then mwcc -w all -o ../beos/nm ../beos/nm.c; fi

prefix="/boot/home/config"

cpp="mwcc -e"

libpth='/boot/beos/system/lib /boot/home/config/lib'
usrinc='/boot/develop/headers/posix'
locinc='/boot/develop/headers/ /boot/home/config/include'

libc='/boot/beos/system/lib/libroot.so'
libs=' '

d_bcmp='define'
d_bcopy='define'
d_bzero='define'
d_index='define'
#d_htonl='define' # It exists, but much hackery would be required to support.
# a bunch of extra includes would have to be added, and it's only used at
# one place in the non-socket perl code.

#these are all in libdll.a, which my version of nm doesn't know how to parse.
#if I can get it to both do that, and scan multiple library files, perhaps
#these can be gotten rid of.

usemymalloc='n'
# Hopefully, Be's malloc knows better than perl's.

d_link='undef'
dont_use_nlink='define'
# no posix (aka hard) links for us!

d_syserrlst='undef'
# the array syserrlst[] is useless for the most part.
# large negative numbers really kind of suck in arrays.

#d_socket='undef'
# Sockets really don't work with the current version of perl and the
# current BeOS sockets; I suspect that a new module a la GSAR's WIN32 port
# will be required.

sig_name='ZERO HUP INT QUIT ILL CHLD ABRT PIPE FPE KILL STOP BUS CONT TSTP ALRM TERM TTIN TTOU USR1 USR2 WINCH THR'
sig_num='0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21'

# Sigh. the parsing of the signal's include file kinda sucks, and produces
# bad results. Easier to just hardcode it.  These signals are guaranteed to
# exist and not change in PR2 and above.

export PATH="$PATH:$PWD/beos"
