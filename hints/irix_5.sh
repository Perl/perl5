# irix_5.sh
# Last modified Fri May  5 11:01:23 EDT 1995
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
