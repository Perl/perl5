# hints/netbsd.sh
case "$osvers" in
0.9|0.8)
	usedl="$undef"
	;;
*)	d_dlopen="$define"
	cccdlflags='-DPIC -fpic'
	lddlflags='-Bforcearchive -Bshareable'
	;;
esac
