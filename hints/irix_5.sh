# irix_5.sh
# Last modified Tue Jan  2 14:52:36 EST 1996
# Apparently, there's a stdio bug that can lead to memory
# corruption using perl's malloc, but not SGI's malloc.
usemymalloc='n'

ld=ld
i_time='define'

case "$cc" in
*gcc) ccflags="$ccflags -D_BSD_TYPES" ;;
*) ccflags="$ccflags -D_POSIX_SOURCE -ansiposix -D_BSD_TYPES -Olimit 3000" ;;
esac

lddlflags="-shared"
# For some reason we don't want -lsocket -lnsl or -ldl.  Can anyone
# contribute an explanation?
set `echo X "$libswanted "|sed -e 's/ socket / /' -e 's/ nsl / /' -e 's/ dl / /'`
shift
libswanted="$*"
