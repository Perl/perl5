# hints/hpux_9.sh, Perl Configure hints file for Hewlett Packard HP/UX 9.x
# Use Configure -Dcc=gcc to use gcc.
ccflags="$ccflags -D_POSIX_SOURCE -D_HPUX_SOURCE"
case "$cc" in
'') if cc $ccflags -Aa 2>&1 | $contains 'Unknown option "A"' >/dev/null
    then			# The bundled (limited) compiler doesn't
	case "$usedl" in	# support -Aa for "ANSI C mode".
	 '') usedl="$undef";;	# Nor can it produce shared libraries.
	esac
    else
	ccflags="$ccflags -Aa"	# The add-on compiler supports ANSI C
    fi
    optimize='+O1'
    ;;
esac
libswanted='m dld'
# ccdlflags="-Wl,-E -Wl,-a,shared $ccdlflags"  # Force all shared?
ccdlflags="-Wl,-E $ccdlflags"
usemymalloc='y'
alignbytes=8
selecttype='int *' 
POSIX_cflags='ccflags="$ccflags -DFLT_MIN=1.17549435E-38"'

case "$prefix" in
'') prefix='/opt/perl5' ;;
esac
case "$archname" in
'') archname='hpux' ;;
esac
