######################################################################
#
# IMPORTANT: before you run 'make', you need to enter one of these two
# lines (depending on your shell):
#	 DYLD_LIBRARY_PATH=`pwd`; export DYLD_LIBRARY_PATH
# or
#	setenv DYLD_LIBRARY_PATH `pwd`
#
######################################################################

# Posix support has been removed from NextStep 
#
useposix='undef'

libpth='/lib /usr/lib'
libswanted=' '
libc='/NextLibrary/Frameworks/System.framework/System'

ldflags='-dynamic -prebind'
lddlflags='-dynamic -bundle -undefined suppress'
ccflags='-dynamic -fno-common -DUSE_NEXT_CTYPE -DUSE_PERL_SBRK -DHIDEMYMALLOC'
cccdlflags='none'
ld='cc'
#optimize='-g -O'

#
# Change the lines below if you do not want to build 'quad-fat'
# binaries
#
archs=`/bin/lipo -info /usr/lib/libm.a | sed 's/^[^:]*:[^:]*: //'`
for d in  $archs
do
       mab="$mab -arch $d"
done

ccflags="$ccflags $mab"
ccdlflags="$mab"
# Can we also set ld='libtool -xxx' ?

useshprlib='true'
dlext='bundle'
so='dylib'

#
# The default prefix would be '/usr/local'. But since many people are
# likely to have still 3.3 machines on their network, we do not want
# to overwrite possibly existing 3.3 binaries. 
# Allow a Configure -Dprefix=/foo/bar override.
#
case "$prefix" in
'') prefix='/usr/local/OPENSTEP' ;;
esac

#archlib='/usr/lib/perl5'
#archlibexp='/usr/lib/perl5'
archname='OPENSTEP-Mach'

d_strcoll='undef'
i_dbm='define'
i_utime='undef'
groupstype='int'
direntrytype='struct direct'

######################################################################
# THE MALLOC STORY
######################################################################
# 1994:
# the simple program `for ($i=1;$i<38771;$i++){$t{$i}=123}' fails
# with Larry's malloc on NS 3.2 due to broken sbrk()
#
# setting usemymalloc='n' was the solution back then. Later came
# reports that perl would run unstable on 3.2:
#
# From about perl5.002beta1h perl became unstable on the
# NeXT. Intermittent coredumps were frequent on 3.2 OS. There were
# reports, that the developer version of 3.3 didn't have problems, so it
# seemed pretty obvious that we had to work around an malloc bug in 3.2.
# This hints file reflects a patch to perl5.002_01 that introduces a
# home made sbrk routine (remember, NeXT's sbrk _never_ worked). This
# sbrk makes it possible to run perl with its own malloc. Thanks to
# Ilya who showed me the way to his sbrk for OS/2!!
# andreas koenig, 1996-06-16
#
# So, this hintsfile is using perl's malloc. If you want to turn perl's
# malloc off, you need to change remove '-DUSE_PERL_SBRK' and 
# '-DHIDEMYMALLOC' from the ccflags above and set usemymalloc below
# to 'n'.
#
######################################################################
usemymalloc='y'
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
