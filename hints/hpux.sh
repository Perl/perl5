#!/usr/bin/sh

### SYSTEM ARCHITECTURE

# Determine the architecture type of this system.
# Keep leading tab below -- Configure Black Magic -- RAM, 03/02/97
	xxOsRevMajor=`uname -r | sed -e 's/^[^0-9]*//' | cut -d. -f1`;
if [ "$xxOsRevMajor" -ge 10 ]; then
    # This system is running >= 10.x

    # Tested on 10.01 PA1.x and 10.20 PA[12].x.
    # Idea: Scan /usr/include/sys/unistd.h for matches with
    # "#define CPU_* `getconf # CPU_VERSION`" to determine CPU type.
    # Note the text following "CPU_" is used, *NOT* the comment.
    #
    # ASSUMPTIONS: Numbers will continue to be defined in hex -- and in
    # /usr/include/sys/unistd.h -- and the CPU_* #defines will be kept
    # up to date with new CPU/OS releases.
    xxcpu=`getconf CPU_VERSION`; # Get the number.
    xxcpu=`printf '0x%x' $xxcpu`; # convert to hex
    archname=`sed -n -e "s/^#[ \t]*define[ \t]*CPU_//p" /usr/include/sys/unistd.h |
	sed -n -e "s/[ \t]*$xxcpu[ \t].*//p" |
	sed -e s/_RISC/-RISC/ -e s/HP_// -e s/_/./`;
else
    # This system is running <= 9.x
    # Tested on 9.0[57] PA and [78].0 MC680[23]0.  Idea: After removing
    # MC6888[12] from context string, use first CPU identifier.
    #
    # ASSUMPTION: Only CPU identifiers contain no lowercase letters.
    archname=`getcontext | tr ' ' '\012' | grep -v '[a-z]' | grep -v MC688 |
	sed -e 's/HP-//' -e 1q`;
    selecttype='int *'
    fi

echo "Archname is $archname"


### HP-UX OS specific behaviour

# Initial setting of some flags
ccflags="$ccflags -D_HPUX_SOURCE"
ldflags="$ldflags -D_HPUX_SOURCE"

# When HP-UX runs a script with "#!", it sets argv[0] to the script name.
toke_cflags='ccflags="$ccflags -DARG_ZERO_IS_SCRIPT"'

cc=${cc:-cc}

ar=/usr/bin/ar	# Yes, truly override.  We do not want the GNU ar.
full_ar=$ar	# I repeat, no GNU ar.  arrr.

case `$cc -v 2>&1`"" in
    *gcc*)  ccisgcc="$define" ;;
    *)      ccisgcc=''
	    ccversion=`which cc | xargs what | awk '/Compiler/{print $2}'`
	    case "`getconf KERNEL_BITS 2>/dev/null`" in
		*64*) ldflags="$ldflags -Wl,+vnocompatwarnings" ;;
		esac
	    case "$d_casti32" in
		"") d_casti32='undef' ;;
		esac
	    ;;
    esac

set `echo X "$libswanted "| sed -e 's/ BSD//' -e 's/ PW//'`
shift
libswanted="$*"


### 64 BITNESS

case "$use64bitall" in
    $define|true|[yY]*) use64bitint="$define" ;;
    esac

case "$usemorebits" in
    $define|true|[yY]*) use64bitint="$define"; uselongdouble="$define" ;;
    esac

case "$uselongdouble" in
    $define|true|[yY]*)
	cat <<EOM >&4

*** long doubles are not (yet) supported on HP-UX (any version)
*** Until it does, we cannot continue, aborting.
EOM
	exit 1 ;;
    esac

case "$use64bitint" in
    $define|true|[Yy])

	if [ "$xxOsRevMajor" -lt 11 ]; then
	    cat <<EOM >&4

*** 64-bit compilation is not supported on HP-UX $xxOsRevMajor.
*** You need at least HP-UX 11.0.
*** Cannot continue, aborting.
EOM
	    exit 1
	    fi

	# Set libc and the library paths
	case "$archname" in
	    PA-RISC*)
		loclibpth="$loclibpth /lib/pa20_64"
		libc='/lib/pa20_64/libc.sl' ;;
	    IA64*) 
		loclibpth="$loclibpth /usr/lib/hpux64"
		libc='/usr/lib/hpux64/libc.so' ;;
	    esac
	if [ ! -f "$libc" ]; then
	    cat <<EOM >&4

*** You do not seem to have the 64-bit libc.
*** I cannot find the file $libc.
*** Cannot continue, aborting.
EOM
	    exit 1
	    fi

	ccflags="$ccflags +DD64"
	ldflags="$ldflags +DD64"

	# Reset the library checker to make sure libraries
	# are the right type
	libscheck='case "`/usr/bin/file $xxx`" in
		       *ELF-64*|*LP64*|*PA-RISC2.0*) ;;
		       *) xxx=/no/64-bit$xxx ;;
		       esac'

	;;

    *)	# Not in 64-bit mode

	case "$archname" in
	    PA-RISC*)
		libc='/lib/libc.sl' ;;
	    IA64*) 
		loclibpth="$loclibpth /usr/lib/hpux32"
		libc='/usr/lib/hpux32/libc.so' ;;
	    esac
	;;
    esac


### COMPILER SPECIFICS

case "$ccisgcc" in
    $define|true|[Yy])
	
	case "$optimize" in
	    "") optimize="-g -O" ;;
	    esac
	ld="$cc"
	cccdlflags='-fPIC'
	lddlflags='-shared'
	;;

    *)	# HP's compiler cannot combine -g and -O
	case "$optimize" in
	    "") optimize="-O" ;;
	    esac
	ld=/usr/bin/ld
	cccdlflags='+Z'
	lddlflags='-b'
	;;
    esac


## LARGEFILES

case "$uselargefiles-$ccisgcc" in
    "$define-$define"|'-define') 
	cat <<EOM >&4

*** I'm ignoring large files for this build because
*** I don't know how to do use large files in HP-UX using gcc.

EOM
	uselargefiles="$undef"
	;;
    esac

cat >UU/uselargefiles.cbu <<'EOCBU'
# This script UU/uselargefiles.cbu will get 'called-back' by Configure 
# after it has prompted the user for whether to use large files.
case "$uselargefiles" in
    ""|$define|true|[yY]*)
	# there are largefile flags available via getconf(1)
	# but we cheat for now.  (Keep that in the left margin.)
ccflags_uselargefiles="-D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64"

	ccflags="$ccflags $ccflags_uselargefiles"

        if test -z "$ccisgcc" -a -z "$gccversion"; then
	    # The strict ANSI mode (-Aa) doesn't like large files.
	    ccflags=`echo " $ccflags "|sed 's@ -Aa @ @g'`
	    case "$ccflags" in
		*-Ae*) ;;
		*)     ccflags="$ccflags -Ae" ;;
		esac
	    fi
	;;
    esac
EOCBU

# THREADING

# This script UU/usethreads.cbu will get 'called-back' by Configure 
# after it has prompted the user for whether to use threads.
cat >UU/usethreads.cbu <<'EOCBU'
case "$usethreads" in
    $define|true|[yY]*)
	if [ "$xxOsRevMajor" -lt 10 ]; then
	    cat <<EOM >&4

HP-UX $xxOsRevMajor cannot support POSIX threads.
Consider upgrading to at least HP-UX 11.
Cannot continue, aborting.
EOM
	    exit 1
	    fi

	if [ "$xxOsRevMajor" -eq 10 ]; then
	    # Under 10.X, a threaded perl can be built
	    if [ -f /usr/include/pthread.h ]; then
		if [ -f /usr/lib/libcma.sl ]; then
		    # DCE (from Core OS CD) is installed

		    # It needs # libcma and OLD_PTHREADS_API. Also
		    # <pthread.h> needs to be #included before any
		    # other includes (in perl.h)

		    # HP-UX 10.X uses the old pthreads API
		    d_oldpthreads="$define"

		    # include libcma before all the others
		    libswanted="cma $libswanted"

		    # tell perl.h to include <pthread.h> before other
		    # include files
		    ccflags="$ccflags -DPTHREAD_H_FIRST"

		    # CMA redefines select to cma_select, and cma_select
		    # expects int * instead of fd_set * (just like 9.X)
		    selecttype='int *'

		elif [ -f /usr/lib/libpthread.sl ]; then
		    # PTH package is installed
		    libswanted="pthread $libswanted"
		else
		    libswanted="no_threads_available"
		    fi
	    else
		libswanted="no_threads_available"
		fi

	    if [ $libswanted = "no_threads_available" ]; then
		cat <<EOM >&4

In HP-UX 10.X for POSIX threads you need both of the files
/usr/include/pthread.h and either /usr/lib/libcma.sl or /usr/lib/libpthread.sl.
Either you must upgrade to HP-UX 11 or install a posix thread library:

    DCE-CoreTools from HP-UX 10.20 Hardware Extensions 3.0 CD (B3920-13941)

or

    PTH package from e.g. http://hpux.tn.tudelft.nl/hppd/hpux/alpha.html

Cannot continue, aborting.
EOM
		exit 1
		fi
	else
	    # 12 may want upping the _POSIX_C_SOURCE datestamp...
	    ccflags=" -D_POSIX_C_SOURCE=199506L $ccflags"
	    set `echo X "$libswanted "| sed -e 's/ c / pthread c /'`
	    shift
	    libswanted="$*"
	    fi

	usemymalloc='n'
	;;
    esac
EOCBU
