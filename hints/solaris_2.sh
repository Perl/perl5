usevfork=false
d_suidsafe=define
set `echo $glibpth | sed -e 's@/usr/ucblib@@'`
glibpth="$*"
# Remove bad libraries.  -lucb contains incompatible routines.
# -lld doesn't do anything useful.
# -lmalloc can cause a problem with GNU CC & Solaris.  Specifically,
# libmalloc.a may allocate memory that is only 4 byte aligned, but
# GNU CC on the Sparc assumes that doubles are 8 byte aligned.
# Thanks to  Hallvard B. Furuseth <h.b.furuseth@usit.uio.no>
set `echo " $libswanted " | sed -e 's@ ld @ @' -e 's@ malloc @ @' -e 's@ ucb @ @'`
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

