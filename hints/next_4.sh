# Posix support has been removed from NextStep, expect test/POSIX to fail 
#
# IMPORTANT: before you run 'make', you need to enter one of these two
# lines (depending on your shell):
#	 DYLD_LIBRARY_PATH=`pwd`; export DYLD_LIBRARY_PATH
# or
#	setenv DYLD_LIBRARY_PATH `pwd`
#
useposix='undef'

altmake='gnumake'
libpth='/lib /usr/lib'
libswanted=' '
libc='/NextLibrary/Frameworks/System.framework/System'

isnext_4='define'
mab='-arch m68k -arch i386 -arch sparc'
ldflags='-dynamic -prebind'
lddlflags='-dynamic -bundle -undefined suppress'
ccflags='-dynamic -fno-common -DUSE_NEXT_CTYPE'
cccdlflags='none'
ld='cc'
optimize='-g -O'

d_shrplib='define'
dlext='bundle'
so='dylib'

prefix='/usr/local/OPENSTEP'
#archlib='/usr/lib/perl5'
#archlibexp='/usr/lib/perl5'
archname='OPENSTEP-Mach'

d_strcoll='undef'
i_dbm='define'
i_utime='undef'
groupstype='int'
direntrytype='struct direct'

# the simple program `for ($i=1;$i<38771;$i++){$t{$i}=123}' fails
# with Larry's malloc on NS 3.2 due to broken sbrk()
usemymalloc='n'
clocktype='int'

#
# On some NeXT machines, the timestamp put by ranlib is not correct, and
# this may cause useless recompiles.  Fix that by adding a sleep before
# running ranlib.  The '5' is an empirical number that's "long enough."
# (Thanks to Andreas Koenig <k@franz.ww.tu-berlin.de>)
ranlib='sleep 5; /bin/ranlib' 
#
# There where reports that the compiler on HPPA machines
# fails with the -O flag on pp.c.
# But since there is no HPPA for OPENSTEP...
# pp_cflags='optimize="-g"'
