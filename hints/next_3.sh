# This file has been put together by Anno Siegel <siegel@zrz.TU-Berlin.DE>,
# Andreas Koenig <k@franz.ww.TU-Berlin.DE> and Gerd Knops <gerti@BITart.com>.
# Comments, questions, and improvements welcome!
#
# These hints work for NeXT 3.2 and 3.3.  3.0 has it's own
# special hint file.
#

ccflags='-DUSE_NEXT_CTYPE -DUSE_PERL_SBRK -DHIDEMYMALLOC'
ldflags='-u libsys_s'
libswanted='dbm gdbm db'

lddlflags='-nostdlib -r'
# Give cccdlflags an empty value since Configure will detect we are
# using GNU cc and try to specify -fpic for cccdlflags.
cccdlflags=' '

#
# Change the line below if you do not want to build 'quad-fat'
# binaries
#
archs=`/bin/lipo -info /usr/lib/libm.a | sed 's/^[^:]*:[^:]*: //'`
for d in  $archs
do
       mab="$mab -arch $d"
done


archname='next-fat'
ld='cc'

i_utime='undef'
groupstype='int'
direntrytype='struct direct'
d_strcoll='undef'

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

d_uname='define'
# setpgid() is in the posix library, but we don't use -posix, so
# we don't see it.  ext/POSIX/POSIX.xs  *does* use -posix, so
# setpgid is still available as POSIX::setpgid.
# See ext/POSIX/POSIX/hints/next.pl.
d_setpgid='undef'
d_setsid='define'
d_tcgetpgrp='define'
d_tcsetpgrp='define'

#
# On some NeXT machines, the timestamp put by ranlib is not correct, and
# this may cause useless recompiles.  Fix that by adding a sleep before
# running ranlib.  The '5' is an empirical number that's "long enough."
#
ranlib='sleep 5; /bin/ranlib' 

#
# There where reports that the compiler on HPPA machines
# fails with the -O flag on pp.c.
# Compiling pp.c with -O for HPPA machines results in a broken perl.
# This is true whether we're on an HPPA machine or cross-compiling
# for one.
pp_cflags='optimize=""'
