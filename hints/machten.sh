# machten.sh
# This is for MachTen 4.0.3.  It might work on other versions and variants too.
#
# Users of earlier MachTen versions might need a fixed tr from ftp.tenon.com.
# This should be described in the MachTen release notes.
#
# MachTen 2.x has its own hint file.
#
# This file has been put together by Andy Dougherty
# <doughera@lafcol.lafayette.edu> based on comments from lots of
# folks, especially 
# 	Mark Pease <peasem@primenet.com>
#	Martijn Koster <m.koster@webcrawler.com>
#	Richard Yeh <rcyeh@cco.caltech.edu>
#
# Use of semctl() can crash system: disable -- Dominic Dunlop 980506
# Raise stack size further; slight tweaks to accomodate MT 4.1
#                      -- Dominic Dunlop <domo@computer.org> 980211
# Raise perl's stack size -- Dominic Dunlop <domo@tcp.ip.lu> 970922
# Reinstate sigsetjmp iff version is 4.0.3 or greater; use nm
# (assumes Configure change); prune libswanted -- Dominic Dunlop 970113
# Warn about test failure due to old Berkeley db -- Dominic Dunlop 970105
# Do not use perl's malloc; SysV IPC OK -- Neil Cutcliffe, Tenon 961030
# File::Find's use of link count disabled by Dominic Dunlop 960528
# Perl's use of sigsetjmp etc. disabled by Dominic Dunlop 960521
#
# Comments, questions, and improvements welcome!
#
# MachTen 4.X does support dynamic loading, but perl doesn't
# know how to use it yet.

# Power MachTen is a real memory system and its standard malloc
# has been optimized for this. Using this malloc instead of Perl's
# malloc may result in significant memory savings.
usemymalloc='false'

# Make symbol table listings les voluminous
nmopts=-gp

# Increase perl's stack size.  Without this, lib/complex.t crashes out.
# Particularly perverse programs may require that perl has an even larger
# stack allocation than that specified here.  (See  man setstackspace )
ldflags='-Xlstack=0x018000'

# Install in /usr/local by default
prefix='/usr/local'

# At least on PowerMac, doubles must be aligned on 8 byte boundaries.
# I don't know if this is true for all MachTen systems, or how to
# determine this automatically.
alignbytes=8

# 4.0.2 and earlier had a problem with perl's use of sigsetjmp and
# friends.  Use setjmp and friends instead.
expr "$osvers" \< "4.0.3" > /dev/null && d_sigsetjmp='undef'

# semctl(.., ..,  IPC_STATUS, ..) hangs system: say we don't have semctl()
d_semctl='undef'

# Get rid of some extra libs which it takes Configure a tediously
# long time never to find on MachTen
set `echo X "$libswanted "|sed -e 's/ net / /' -e 's/ socket / /' \
    -e 's/ inet / /' -e 's/ nsl / /' -e 's/ nm / /' -e 's/ malloc / /' \
    -e 's/ ld / /' -e 's/ sun / /' -e 's/ posix / /' \
    -e 's/ cposix / /' -e 's/ crypt / /' \
    -e 's/ ucb / /' -e 's/ bsd / /' -e 's/ BSD / /' -e 's/ PW / /'`
shift
libswanted="$*"

# While link counts on MachTen 4.1's fast file systems work correctly,
# on Macintosh Heirarchical File Systems, (and on HFS+)
# MachTen always reports ony two links to directories, even if they
# contain subdirectories.  Consequently, we use this variable to stop
# File::Find using the link count to determine whether there are
# subdirectories to be searched.  This will generate a harmless message:
# Hmm...You had some extra variables I don't know about...I'll try to keep 'em.
#	Propagating recommended variable dont_use_nlink
dont_use_nlink=define

cat <<'EOM' >&4

During Configure, you may see the message

*** WHOA THERE!!! ***
    The recommended value for $d_semctl on this machine was "undef"!
    Keep the recommended value? [y]

Select the default answer: semctl() is buggy, and perl should be built
without it.

At the end of Configure, you will see a harmless message

Hmm...You had some extra variables I don't know about...I'll try to keep 'em.
	Propagating recommended variable dont_use_nlink
        Propagating recommended variable nmopts
Read the File::Find documentation for more information about dont_use_nlink

Tests
	io/fs test 4  and
	op/stat test 3
may fail since MachTen may not return a useful nlinks field to stat
on directories.

EOM
expr "$osvers" \< "4.1" >/dev/null && test -r ./broken-db.msg && \
    . ./broken-db.msg
