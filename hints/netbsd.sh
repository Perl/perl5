# hints/netbsd.sh
#
# talk to packages@netbsd.org if you want to change this file.
#
# netbsd keeps dynamic loading dl*() functions in /usr/lib/crt0.o,
# so Configure doesn't find them (unless you abandon the nm scan).
# this should be *just* 0.9 below as netbsd 0.9a was the first to
# introduce shared libraries.

case "$archname" in
'')
    archname=`uname -m`-${osname}
    ;;
esac

case "$osvers" in
0.9|0.8*)
	usedl="$undef"
	;;
*)
	if [ -f /usr/libexec/ld.elf_so ]; then
		d_dlopen=$define
		d_dlerror=$define
		# Include the whole libgcc.a, required for Xerces-P, which
		# needs __eh_alloc, __pure_virtual, and others.
		# XXX This should be obsoleted by gcc-3.0.
		ccdlflags="-Wl,-whole-archive -lgcc -Wl,-no-whole-archive \
			-Wl,-E -Wl,-R${PREFIX}/lib $ccdlflags"
		cccdlflags="-DPIC -fPIC $cccdlflags"
		lddlflags="--whole-archive -shared $lddlflags"
	elif [ "`uname -m`" = "pmax" ]; then
# NetBSD 1.3 and 1.3.1 on pmax shipped an `old' ld.so, which will not work.
		case "$osvers" in
		1.3|1.3.1)
			d_dlopen=$undef
			;;
		esac
	elif [ -f /usr/libexec/ld.so ]; then
		d_dlopen=$define
		d_dlerror=$define
		ccdlflags="-Wl,-R${PREFIX}/lib $ccdlflags"
# we use -fPIC here because -fpic is *NOT* enough for some of the
# extensions like Tk on some netbsd platforms (the sparc is one)
		cccdlflags="-DPIC -fPIC $cccdlflags"
		lddlflags="-Bshareable $lddlflags"
	else
		d_dlopen=$undef
	fi
	;;
esac

# netbsd had these but they don't really work as advertised, in the
# versions listed below.  if they are defined, then there isn't a
# way to make perl call setuid() or setgid().  if they aren't, then
# ($<, $>) = ($u, $u); will work (same for $(/$)).  this is because
# you can not change the real userid of a process under 4.4BSD.
# netbsd fixed this in 1.3.2.
case "$osvers" in
0.9*|1.[012]*|1.3|1.3.1)
	d_setregid="$undef"
	d_setreuid="$undef"
	;;
esac

# These are obsolete in any netbsd.
d_setrgid="$undef"
d_setruid="$undef"

# there's no problem with vfork.
usevfork=true

# Using perl's malloc leads to trouble on some toolchain versions.
usemymalloc="$undef"

# Pre-empt the /usr/bin/perl question of installperl.
installusrbinperl="$undef"

# This is there but in machine/ieeefp_h.
ieeefp_h="define"

# This script UU/usethreads.cbu will get 'called-back' by Configure 
# after it has prompted the user for whether to use threads. 
cat > UU/usethreads.cbu <<'EOCBU' 
case "$usethreads" in 
$define|true|[yY]*) 
        # The GNU pth is the recommended user-level pthreads implementation. 
        # As of NetBSD 1.5.2 there are no kernel pthreads. 
        if pkg_info -qe pth; then 
            # Add -lpthread. 
            libswanted="$libswanted pthread" 
            # -R so that we find the libpthread.so from /usr/pkg/lib
            # during Configure and build.
            ldflags="-R/usr/pkg/lib $ldflags" 
            # There is no libc_r as of NetBSD 1.5.2, so no c -> c_r. 
        else 
            echo "$0: You need to install the GNU pth.  Aborting." >&4 
            exit 1 
        fi 
        ;; 
esac 
EOCBU 

# Recognize the NetBSD packages collection.
# GDBM might be here.
test -d /usr/pkg/lib     && loclibpth="$loclibpth /usr/pkg/lib"
test -d /usr/pkg/include && locincpth="$locincpth /usr/pkg/include"
