# svr4 hints, System V Release 4.x
# Use Configure -Dcc=gcc to use gcc.
case "$cc" in
'') cc='/bin/cc'
    test -f $cc || cc='/usr/ccs/bin/cc'
    cccdlflags='-Kpic'	# Probably needed for dynamic loading
    ;;
esac
test -d /usr/local/man || mansrc='none'
# We include support for using libraries in /usr/ucblib, but the setting
# of libswanted excludes some libraries found there.  You may want to
# prevent "ucb" from being removed from libswanted and see if perl will
# build on your system.
ldflags='-L/usr/ccs/lib -L/usr/ucblib'
ccflags='-I/usr/include -I/usr/ucbinclude'
libswanted=`echo $libswanted | tr ' ' '\012' | egrep -v '^(malloc|ucb)$'`
# -lucb: Defines setreuid() and other routines Perl wants but they don't
#	 add any/much functionality and often won't ld properly.
# -lmalloc: Anyone know what problems this caused?
if [  "" = "$i_ndbm"  -a  ! -f /usr/ucblib/libndbm.a  ]; then
# UnixWare 1.1 may install /usr/ucbinclude/ndbm.h w/o /usr/ucblib/libndbm.a
    i_ndbm="$undef"	# so Configure tries to build ext/NDBM_File and ld
fi	# can't find dbm_open()!  "./Configure -D i_ndbm=define" overrides.
d_index='undef'
d_suidsafe=define	# "./Configure -d" can't figure this out
lddlflags="-G $ldflags"	# Probably needed for dynamic loading
usevfork='false'
# dlopen routines exist but they don't work with perl.
# The case statement allows experimenters to override hint with
# Configure -D usedl
case "$usedl" in
'') usedl="$undef" ;;	
esac
