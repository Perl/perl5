# hints/dec_osf_2_0.sh
d_odbm='undef'              # We don't need both odbm and ndbm
gidtype='gid_t'
groupstype='gid_t'
d_voidshmat='define'
clocktype='time_t'
libpth="$libpth /usr/shlib" # Use the shared libraries if possible
libc='/usr/shlib/libc.so'   # The archive version is /lib/libc.a
case `uname -m` in
    mips|alpha)   optimize="$optimize -g"
                  ccflags="$ccflags -D_BSD -DSTANDARD_C -DDEBUGGING" ;;
    *)            ccflags="$ccflags -D_BSD -DSTANDARD_C -DDEBUGGING" ;;
esac
