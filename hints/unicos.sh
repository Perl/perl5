case `uname -r` in
6.1*) shellflags="-m+65536" ;;
esac
case "$optimize" in
'') optimize="-O1 -h nofastmd" ;;
esac
case `uname -r` in
10.*) pp_ctl_cflags='ccflags="$ccflags -DUNICOS_BROKEN_VOLATILE' ;;
esac
d_setregid='undef'
d_setreuid='undef'
case "$usemymalloc" in
'') # The perl malloc.c SHOULD work in Unicos (ILP64) says Ilya.
    # But for the time being (5.004_68), alas, it doesn't. --jhi
    # usemymalloc='y'
    # ccflags="$ccflags -DNO_RCHECK"
    usemymalloc='n'
    ;;
esac
# Configure gets fooled for some reason.  There is no getpgid().
d_getpgid='undef'
