# irix_5.sh
i_time='define'
ccflags="$ccflags -D_POSIX_SOURCE -ansiposix -D_BSD_TYPES -Olimit 3000"
lddlflags="-shared"
set `echo X "$libswanted "|sed -e 's/ socket / /' -e 's/ nsl / /' -e 's/ dl / /'`
shift
libswanted="$*"
