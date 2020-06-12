# Haiku hints file
# $Id$

case "$prefix" in
'') prefix="/boot/common" ;;
*) ;; # pass the user supplied value through
esac

libpth='/boot/home/config/lib /boot/common/lib /system/lib'
usrinc='/boot/system/develop/headers/posix'
locinc='/boot/home/config/include /boot/common/include /boot/develop/headers'

libc='/system/lib/libroot.so'
libs='-lnetwork'

# Use Haiku's malloc() by default.
case "$usemymalloc" in
'') usemymalloc='n' ;;
esac

# Haiku generally supports hard links, but the default file system (BFS)
# doesn't. So better avoid using hard links.
d_link='undef'
dont_use_nlink='define'

# The array syserrlst[] is useless for the most part.
# Large negative numbers really kind of suck in arrays.
d_syserrlst='undef'

# Haiku uses gcc.
cc="gcc"
ld='gcc'

# The runtime loader library path variable is LIBRARY_PATH.
case "$ldlibpthname" in
'') ldlibpthname=LIBRARY_PATH ;;
esac

# as of alpha 4.1 (at the latest) some symbols are versioned,
# confusing the nm lookup
case "$usenm" in
'') usenm='undef' ;;
esac

