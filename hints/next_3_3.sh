# This file has been put together by Anno Siegel <siegel@zrz.TU-Berlin.DE>
# and Andreas Koenig <k@franz.ww.TU-Berlin.DE>. Comments, questions, and
# improvements welcome!
#

# These hints are intended for NeXT 3.3. If you're running the 3.3
# "user" version of the NeXT OS, you should not change the malloc
# related hints (USE_PERL_SBRK, HIDEMYMALLOC, usemymalloc). If you're
# running the 3.3 "dev" version of the OS, I do not know what to
# recommend (I have no 3.3 dev).
 
# From about perl5.002beta1h perl became unstable on the
# NeXT. Intermittent coredumps were frequent on 3.2 OS. There were
# reports, that the developer version of 3.3 didn't have problems, so it
# seemed pretty obvious that we had to work around an malloc bug in 3.2.
# This hints file reflects a patch to perl5.002_01 that introduces a
# home made sbrk routine (remember, NeXT's sbrk _never_ worked). This
# sbrk makes it possible to run perl with its own malloc. Thanks to
# Ilya who showed me the way to his sbrk for OS/2!!
# andreas koenig, 1996-06-16

ccflags='-DUSE_NEXT_CTYPE -DUSE_PERL_SBRK -DHIDEMYMALLOC'
POSIX_cflags='ccflags="-posix $ccflags"'
ldflags='-u libsys_s'
libswanted='dbm gdbm db'

lddlflags='-r'
# Give cccdlflags an empty value since Configure will detect we are
# using GNU cc and try to specify -fpic for cccdlflags.
cccdlflags=' '

i_utime='undef'
groupstype='int'
direntrytype='struct direct'
d_strcoll='undef'

# the simple program `for ($i=1;$i<38771;$i++){$t{$i}=123}' fails
# with Larry's malloc on NS 3.2 due to broken sbrk()
######################################################################
#    above comment should stay here, but is not longer of importance #
# with -DUSE_PERL_SBRK and -DHIDEMYMALLOC we can now say 'yes' to    #
# usemymalloc. We call this hintsfile next_3_2.sh, so folks with 3.3 #
# can decide what they prefer. Actually folks with 3.3 "user" version#
# will also need this hintsfile, but how can I discern which 3.3 it  #
# is?                                                                #
######################################################################
usemymalloc='y'

d_uname='define'
d_setpgid='define'
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
#
if [ `arch` = "hppa" ]; then
pp_cflags='optimize="-g"'
fi
