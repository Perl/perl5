# hints/openbsd.sh
#
# hints file for OpenBSD; Todd Miller <millert@openbsd.org>
#

# OpenBSD has a better malloc than perl...
usemymalloc='n'

# Currently, vfork(2) is not a real win over fork(2) but this will
# change in a future release.
usevfork='true'

# setre?[ug]id() have been replaced by the _POSIX_SAVED_IDS versions
# in 4.4BSD.  Configure will find these but they are just emulated
# and do not have the same semantics as in 4.3BSD.
d_setregid='undef'
d_setreuid='undef'
d_setrgid='undef'
d_setruid='undef'

#
# Not all platforms support shared libs...
#
case `uname -m` in
alpha|mips|powerpc|vax)
	d_dlopen=$undef
	;;
*)
	d_dlopen=$define
	d_dlerror=$define
	# we use -fPIC here because -fpic is *NOT* enough for some of the
	# extensions like Tk on some OpenBSD platforms (ie: sparc)
	cccdlflags="-DPIC -fPIC $cccdlflags"
	lddlflags="-Bforcearchive -Bshareable $lddlflags"
	;;
esac

# OpenBSD doesn't need libcrypt but many folks keep a stub lib
# around for old NetBSD binaries.
libswanted=`echo $libswanted | sed 's/ crypt / /'`

# Avoid telldir prototype conflict in pp_sys.c  (OpenBSD uses const DIR *)
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'

# Configure can't figure this out non-interactively
d_suidsafe='define'

# cc is gcc so we can do better than -O
optimize='-O2'

# end
