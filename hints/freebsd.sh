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
# Additional 2.2 defines from
# Mark Murray <mark@grondar.za>
# Date: Wed, 6 Nov 1996 09:44:58 +0200 (MET)
#
# Modified to ensure we replace -lc with -lc_r, and
# to put in place-holders for various specific hints.
# Andy Dougherty <doughera@lafcol.lafayette.edu>
# Date: Tue Mar 10 16:07:00 EST 1998
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
1.1*)
	malloctype='void *'
	groupstype='int'
	d_setregid='undef'
	d_setreuid='undef'
	d_setrgid='undef'
	d_setruid='undef'
	;;
2.0-release*)
	d_setregid='undef'
	d_setreuid='undef'
	d_setrgid='undef'
	d_setruid='undef'
	;;
#
# Trying to cover 2.0.5, 2.1-current and future 2.1/2.2
# It does not covert all 2.1-current versions as the output of uname
# changed a few times.
#
# Even though seteuid/setegid are available, they've been turned off
# because perl isn't coded with saved set[ug]id variables in mind.
# In addition, a small patch is requried to suidperl to avoid a security
# problem with FreeBSD.
#
2.0.5*|2.0-built*|2.1*)
 	usevfork='true'
	usemymalloc='n'
	d_setregid='define'
	d_setreuid='define'
	d_setegid='undef'
	d_seteuid='undef'
	test -r ./broken-db.msg && . ./broken-db.msg
	;;
#
# 2.2 and above have phkmalloc(3).
# don't use -lmalloc (maybe there's an old one from 1.1.5.1 floating around)
2.2*)
 	usevfork='true'
	usemymalloc='n'
	libswanted=`echo $libswanted | sed 's/ malloc / /'`
	d_setregid='define'
	d_setreuid='define'
	d_setegid='undef'
	d_seteuid='undef'
	;;
#
# Guesses at what will be needed after 2.2
*)	usevfork='true'
	usemymalloc='n'
	libswanted=`echo $libswanted | sed 's/ malloc / /'`
	;;
esac

# Dynamic Loading flags have not changed much, so they are separated
# out here to avoid duplicating them everywhere.
case "$osvers" in
0.*|1.0*) ;;
*)	cccdlflags='-DPIC -fpic'
	lddlflags="-Bshareable $lddlflags"
	;;
esac

cat <<'EOM' >&4

Some users have reported that Configure halts when testing for
the O_NONBLOCK symbol with a syntax error.  This is apparently a
sh error.  Rerunning Configure with ksh apparently fixes the
problem.  Try
	ksh Configure [your options]

EOM

# XXX EXPERIMENTAL  A.D.  03/09/1998
# XXX This script UU/usethreads.cbu will get 'called-back' by Configure
# XXX after it has prompted the user for whether to use threads.
cat > UU/usethreads.cbu <<'EOSH'
case "$usethreads" in
$define)
    if [ ! -r /usr/lib/libc_r.a ]; then
        cat <<'EOM' >&4

The re-entrant C library /usr/lib/libc_r.a does not exist; cannot build
threaded Perl.  Consider upgrading to a newer FreeBSD snapshot or release:
at least the FreeBSD 3.0-971225-SNAP is known to have the libc_r.a.

EOM
        exit 1
    fi
    # Patches to libc_r may be required.
    # Print out a note about them here.

    # These checks by Andy Dougherty <doughera@lafcol.lafayette.edu>
    # Please update or change them as you learn more!
    # -lc_r must REPLACE -lc.  AD  03/10/1998
    set `echo X "$libswanted "| sed -e 's/ c / c_r /'`
    shift
    libswanted="$*"
    # Configure will probably pick the wrong libc to use for nm scan.
    # The safest quick-fix is just to not use nm at all.
    usenm=false
    # Is vfork buggy in 3.0?
    case "$osvers" in
	3.0) usevfork=false ;;
    esac
    ;;
esac
EOSH
# XXX EXPERIMENTAL  --end of call-back
