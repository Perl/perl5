# Oringal based on info from
# Carl M. Fongheiser <cmf@ins.infonet.net>
# Date: Thu, 28 Jul 1994 19:17:05 -0500 (CDT)
#
# Additional 1.1.5 defines from 
# Ollivier Robert <Ollivier.Robert@keltia.frmug.fr.net>
# Date: Wed, 28 Sep 1994 00:37:46 +0100 (MET)
#
case "$osvers" in
0.*|1.0*)
	usedl="$undef"
	;;
*)	d_dlopen="$define"
	cccdlflags='-DPIC -fpic'
	lddlflags='-Bshareable'
	malloctype='void *'
	groupstype='int'
	d_setregid='undef'
	d_setreuid='undef'
	d_setrgid='undef'
	d_setruid='undef'
	i_unistd='undef'
	;;
esac
# Avoid telldir prototype conflict in pp_sys.c  (FreeBSD uses const DIR *)
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'
