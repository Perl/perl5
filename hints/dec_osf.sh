# hints/dec_osf.sh
case "$optimize" in
'')
    case "$cc" in 
    *gcc*) ;;
    *)	optimize='-O2 -Olimit 2900' ;;
    esac
    ;;
esac

ccflags="$ccflags -DSTANDARD_C"

# Check if it's a CMW version of OSF1
if test `uname -s` = "MLS+"; then
    lddlflags='-shared -expect_unresolved "*" -s'
else
    lddlflags='-shared -expect_unresolved "*" -s -hidden'
fi
