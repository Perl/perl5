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
