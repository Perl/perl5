case `uname -r` in
6.1*) shellflags="-m+65536" ;;
esac
case "$optimize" in
'') optimize="-h nofastmd" ;; # fastmd: integer values limited to 46 bits
esac
case `uname -r` in
10.*) pp_ctl_cflags='optimize="$optimize -h scalar 0 -h vector 0"' ;;
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
