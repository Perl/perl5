# hints/netbsd.sh
# netbsd keeps  dynamic loading dl*() functions in /lib/crt0.o,
# so Configure doesn't find them (unless you abandon the nm scan).
case "$osvers" in
0.9*|0.8*)
	usedl="$undef"
	;;
*)	d_dlopen=$define
	d_dlerror=$define
	cccdlflags="-DPIC -fpic $cccdlflags"
	lddlflags="-Bforcearchive -Bshareable $lddlflags"
	;;
esac

# Avoid telldir prototype conflict in pp_sys.c  (NetBSD uses const DIR *)
# Configure should test for this.  Volunteers?
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'
