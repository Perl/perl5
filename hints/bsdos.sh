# hints/bsdi_bsdos.sh
#
# hints file for BSD/OS 2.x (adapted from bsd386.sh)
# Original by Neil Bowers <neilb@khoros.unm.edu>
#     Tue Oct  4 12:01:34 EDT 1994
# Updated by Tony Sanders <sanders@bsdi.com>
#     Mon Mar 13 12:17:24 CST 1995
#
# You can override the compiler and loader on the Configure command line:
#     ./Configure -Dcc=gcc -Dld=ld

# filename extension for shared library objects
so='o'

d_voidsig='define'
signal_t='void'

# If Configure's signal detection fails, uncomment this line.
# sig_name='ZERO HUP INT QUIT ILL TRAP IOT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2 '

d_dosuid='define'

# we don't want to use -lnm, since exp() is busted in there (in 1.1 anyway)
set `echo X "$libswanted "| sed -e 's/ nm / /'`
shift
libswanted="$*"

# Avoid telldir prototype conflict in pp_sys.c  (BSD/386 uses const DIR *)
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'

case "$osvers" in
1.0*)
	# Avoid problems with HUGE_VAL in POSIX in 1.0's cc.
	POSIX_cflags='ccflags="$ccflags -UHUGE_VAL"' 
	;;
1.1*)
	# Use gcc2 (2.5.8) if available in 1.1.
	case "$cc" in
	'')	cc=gcc2 ;;
	esac
	;;
2.*)
	# Use 2.X's gcc2
	case "$cc" in
	'')	cc=gcc2 ;;
	esac

	# Link with shared libraries in 2.X
	case "$ld" in
	'')	ld='shlicc' ;;
	esac

	# setre?[ug]id() have been replaced by the _POSIX_SAVED_IDS stuff
	# in 4.4BSD-based systems (including BSD/OS 2.0 and later).
	# See http://www.bsdi.com/bsdi-man?setuid(2)
	d_setregid='undef'
	d_setreuid='undef'
	d_setrgid='undef'
	d_setruid='undef'
	;;
esac
