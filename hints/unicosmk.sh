case "$optimize" in
'') optimize="-O1" ;;
esac
d_setregid='undef'
d_setreuid='undef'
case "$usemymalloc" in
'') usemymalloc='y'
    ccflags="$ccflags -DNO_RCHECK"
    ;;
esac
# If somebody ignores the Cray PATH.
case ":$PATH:" in
*:/opt/ctl/bin:*) ;;
'') case "$cc" in
    '') test -x /opt/ctl/bin/cc && cc=/opt/ctl/bin/cc ;;
    esac
    ;;
esac
# As of UNICOS/mk 2.0.5.24 the shm* are in libc but unimplemented
# (an attempt to use them causes a runtime error)
# XXX Configure probe for really functional shm*() is needed XXX
if test "$d_shm" = ""; then
    test "$d_shmctl" = "" && d_shmctl="$undef"
    test "$d_shmget" = "" && d_shmget="$undef"
    d_shm="$undef"
fi

