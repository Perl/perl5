#
# hints file for Data General DG/UX
# these hints tweaked for perl5 on an AViiON mc88100, running DG/UX 5.4R2.01
#

gidtype='gid_t'
groupstype='gid_t'
libswanted="dgc $libswanted"
uidtype='uid_t'
d_index='define'
ccflags='-D_POSIX_SOURCE -D_DGUX_SOURCE'

# this hasn't been tried with dynamic loading at all
usedl='false'

#
# an ugly hack, since the Configure test for "gcc -P -" hangs.
# can't just use 'cppstdin', since our DG has a broken cppstdin :-(
#
cppstdin=`cd ..; pwd`/cppstdin
cpprun=`cd ..; pwd`/cppstdin

#
# you don't want to use /usr/ucb/cc
#
cc='gcc'
