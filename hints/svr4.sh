# svr4 hints, System V Release 4.x
# Last modified 1994/12/03 by Tye McQueen, tye@metronet.com
# Use Configure -Dcc=gcc to use gcc.
case "$cc" in
'') cc='/bin/cc'
    test -f $cc || cc='/usr/ccs/bin/cc'
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
d_index='undef'		# Even if libucb.a used, use strchr() not index().
d_suidsafe=define	# "./Configure -d" can't figure this out easilly
usevfork='false'
cat <<'EOM'

If you wish to use dynamic linking, you must use 
	LD_LIBRARY_PATH=`pwd`; export LD_LIBRARY_PATH
or
	setenv LD_LIBRARY_PATH `pwd`
before running make.

EOM
