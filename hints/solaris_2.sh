usevfork=false
d_suidsafe=define
ccflags="$ccflags"
set `echo $glibpth | sed -e 's@/usr/ucblib@@'`
glibpth="$*"
set `echo " $libswanted " | sed -e 's@ ld @ @' -e 's@ ucb @ @'`
libswanted="$*"

# Look for architecture name.  We want to suggest a useful default
# for archlib and also warn about possible -x486 flags needed.
case "$archname" in
'')
    if test -f /usr/bin/arch; then
        archname=`/usr/bin/arch`
    	archname="${archname}-${osname}"
    elif test -f /usr/ucb/arch; then
        archname=`/usr/ucb/arch`
    	archname="${archname}-${osname}"
    fi
    ;;
esac
case "$archname" in
*86*) echo "For an Intel platform you might need to add -x486 to ccflags" >&4;;
*) ;;
esac

case $PATH in
*/usr/ucb*:/usr/bin:*) cat <<END
NOTE:  Some people have reported problems with /usr/ucb/cc.  
Remove /usr/ucb from your PATH if you have difficulties.
END
;;
esac
