libswanted='ndbm m dld'
ccflags="$ccflags -Aa -D_POSIX_SOURCE -D_HPUX_SOURCE"
# ldflags="-Wl,-E -Wl,-a,shared"  # Force all shared?
ldflags="-Wl,-E"
optimize='+O1'
usemymalloc='y'
alignbytes=8
selecttype='int *' 
POSIX_cflags='ccflags="$ccflags -DFLT_MIN=1.17549435E-38"'
