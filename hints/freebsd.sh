# Original based on info from
# Carl M. Fongheiser <cmf@ins.infonet.net>
# Date: Thu, 28 Jul 1994 19:17:05 -0500 (CDT)
#
# Additional 1.1.5 defines from 
# Ollivier Robert <Ollivier.Robert@keltia.frmug.fr.net>
# Date: Wed, 28 Sep 1994 00:37:46 +0100 (MET)
#
# Additional 2.* defines from
# Ollivier Robert <Ollivier.Robert@keltia.frmug.fr.net>
# Date: Sat, 8 Apr 1995 20:53:41 +0200 (MET DST)
#
# Additional 2.0.5 and 2.1 defined from
# Ollivier Robert <Ollivier.Robert@keltia.frmug.fr.net>
# Date: Fri, 12 May 1995 14:30:38 +0200 (MET DST)
#
# FreeBSD has the dynamic loading dl*() functions in /usr/lib/crt0.o,
# so Configure doesn't find them (unless you abandon the nm scan).
#
# The two flags "-fpic -DPIC" are used to indicate a
# will-be-shared object.  Configure will guess the -fpic, (and the
# -DPIC is not used by perl proper) but the full define is included to 
# be consistent with the FreeBSD general shared libs building process.
#
# setreuid and friends are inherently broken in all versions of FreeBSD
# before 2.1-current (before approx date 4/15/95). It is fixed in 2.0.5
# and what-will-be-2.1
#

case "$osvers" in
0.*|1.0*)
	usedl="$undef"
	;;
1.1*)	d_dlopen="$define"
	cccdlflags='-DPIC -fpic'
	lddlflags="-Bshareable $lddlflags"
	malloctype='void *'
	groupstype='int'
	d_setregid='undef'
	d_setreuid='undef'
	d_setrgid='undef'
	d_setruid='undef'
	;;
2.0-RELEASE*)
	d_dlopen="$define"
	cccdlflags='-DPIC -fpic'
	lddlflags="-Bshareable $lddlflags"
	d_setregid='undef'
	d_setreuid='undef'
	d_setrgid='undef'
	d_setruid='undef'
	;;
#
# Trying to cover 2.0.5, 2.1-current and future 2.1
# It does not covert all 2.1-current versions as the output of uname
# changed a few times.
#
2.0.5*|2.0-BUILD|2.1*)
	d_dlopen="$define"
	cccdlflags='-DPIC -fpic'
	lddlflags="-Bshareable $lddlflags"
	# Are these defines necessary?  Doesn't Configure find them
	# correctly?
	d_setregid='define'
	d_setreuid='define'
	d_setrgid='define'
	d_setruid='define'
esac
# Avoid telldir prototype conflict in pp_sys.c  (FreeBSD uses const DIR *)
# Configure should test for this.  Volunteers?
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'
