case `uname -r` in
6.1*) shellflags="-m+65536" ;;
esac
case "$optimize" in
# If we used fastmd (the default) integer values would be limited to 43 bits.
# --Mark P. Lutz
'') optimize="$optimize -h nofastmd" ;;
esac
# The default is to die on math overflows with an runtime error.
# Let's not do that. --jhi
ccflags="$ccflags -h matherror=errno" 
# Avoid an optimizer bug where a volatile variables
# isn't correctly saved and restored --Mark P. Lutz 
pp_ctl_cflags='ccflags="$ccflags -h scalar0 -h vector0"'
case "$usemymalloc" in
'') # The perl malloc.c SHOULD work says Ilya.
    # But for the time being (5.004_68), alas, it doesn't. --jhi
    # usemymalloc='y'
    # ccflags="$ccflags -DNO_RCHECK"
    usemymalloc='n'
    ;;
esac
# Configure gets fooled for some reason.  There is no getpgid().
d_getpgid='undef'
# These exist but do not really work.
d_setregid='undef'
d_setreuid='undef'
