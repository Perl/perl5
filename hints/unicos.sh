case `uname -r` in
6.1*) shellflags="-m+65536" ;;
esac
ccflags="$ccflags -DHZ=__hertz"
optimize="-O1"
libswanted=m
d_setregid='undef'
d_setreuid='undef'

# Pick up dbm.h in <rpcsvc/dbm.h>
if test -f /usr/include/rpcsvc/dbm.h; then
    ccflags="$ccflags -I/usr/include/rpcsvc"
fi
