# hints/irix_6_4.sh
#
# Created by John Stoffel (jfs@fluent.com), 02/11/1997
# Based on the Irix 6.2 hints file, but simplified.

# Configure can't parse 'nm' output on Irix 6.4
usenm='n'

# The new Irix IDO v7.1 compiler is strange...
  
irix_hint_cc=`cc -version 2>&1`
case "$irix_hint_cc" in
*7.1*)
	ccflags="$ccflags -OPT:Olimit=13000 -w"
	optimize="-O2"
	;;
*)
	ccflags="$ccflags -Olimit 3000"
	;;
esac
unset irix_hint_cc

pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'

# Gets rid of some extra libs that don't seem to be really needed.
# See the Irix 6.2 hints file for some justifications.
set `echo X "$libswanted "|sed -e 's/ sun / /' -e 's/ crypt / /' -e 's/ bsd / /' -e 's/ PW / /' -e 's/ dl / /' -e 's/ socket / /' -e 's/ nsl / /'`
shift
libswanted="$*"
