# hints file for BSD/386 1.x
# Original by Neil Bowers <neilb@khoros.unm.edu>
# Tue Oct  4 12:01:34 EDT 1994
#
# filename extension for shared libraries
so='o'

d_voidsig='define'
sig_name='ZERO HUP INT QUIT ILL TRAP IOT EMT FPE KILL BUS SEGV SYS PIPE ALRM TERM URG STOP TSTP CONT CHLD TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH INFO USR1 USR2 '
signal_t='void'

# we don't want to use -lnm, since exp() is busted in there (in 1.1 anyway)
set `echo X "$libswanted "| sed -e 's/ nm / /'`
shift
libswanted="$*"

# Avoid telldir prototype conflict in pp_sys.c  (BSD/386 uses const DIR *)
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'

# Avoid problems with HUGE_VAL in POSIX in 1.0's cc.
# Use gcc2 (2.5.8) if available in 1.1.
case "$osvers" in
1.0*)
	POSIX_cflags='ccflags="$ccflags -UHUGE_VAL"' 
	;;
1.1*)
	case "$cc" in
	'')	cc=gcc2 ;;
	esac
	;;
esac
