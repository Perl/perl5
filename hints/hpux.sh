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

# -ldbm is obsolete and should not be used
# -lBSD contains BSD-style duplicates of SVR4 routines that cause confusion
# -lPW is obsolete and should not be used
# The libraries crypt, malloc, ndir, and net are empty.
set `echo "X $libswanted " | sed -e 's/ ld / /' -e 's/ dbm / /' -e 's/ BSD / /' -e 's/ PW / /'`
shift
libswanted="$*"

cc=${cc:-cc}
ar=/usr/bin/ar	# Yes, truly override.  We do not want the GNU ar.
full_ar=$ar	# I repeat, no GNU ar.  arrr.

set `echo "X $ccflags " | sed -e 's/ -A[ea] / /' -e 's/ -D_HPUX_SOURCE / /'`
shift
	cc_cppflags="$* -D_HPUX_SOURCE"
cppflags="-Aa -D__STDC_EXT__ $cc_cppflags"

case "$prefix" in
    "") prefix='/opt/perl5' ;;
    esac

    gnu_as=no
    gnu_ld=no
case `$cc -v 2>&1`"" in
    *gcc*)  ccisgcc="$define"
	    ccflags="$cc_cppflags"
	    case "`getconf KERNEL_BITS 2>/dev/null`" in
		*64*)
		    echo "main(){}">try.c
		    # gcc with gas will not accept +DA2.0
		    case "`$cc -c -Wa,+DA2.0 try.c 2>&1`" in
			*"+DA2.0"*)		# gas
			    gnu_as=yes
			    ;;
			*)			# HPas
                           case "$gccversion" in
                               [12]*) ccflags="$ccflags -Wa,+DA2.0" ;;
                               esac
			    ;;
			esac
		    # gcc with gld will not accept +vnocompatwarnings
		    case "`$cc -o try -Wl,+vnocompatwarnings try.c 2>&1`" in
			*"+vnocompat"*)		# gld
			    gnu_ld=yes
			    ;;
			*)			# HPld
                           case "$gccversion" in
                               [12]*)
                                   ldflags="$ldflags -Wl,+vnocompatwarnings"
                                   ccflags="$ccflags -Wl,+vnocompatwarnings"
                                   ;;
                               esac
			    ;;
			esac
		    ;;
		esac
	    ;;
    *)      ccisgcc=''
	    ccversion=`which cc | xargs what | awk '/Compiler/{print $2}'`
	    ccflags="-Ae $cc_cppflags -Wl,+vnocompatwarnings"
	    # Needed because cpp does only support -Aa (not -Ae)
	    cpplast='-'
	    cppminus='-'
	    cppstdin='cc -E -Aa -D__STDC_EXT__'
	    cpprun=$cppstdin
	    case "$d_casti32" in
		"") d_casti32='undef' ;;
		esac
	    ;;
    esac

# When HP-UX runs a script with "#!", it sets argv[0] to the script name.
toke_cflags='ccflags="$ccflags -DARG_ZERO_IS_SCRIPT"'

### 64 BITNESS

# Some gcc versions do native 64 bit long (e.g. 2.9-hppa-000310 and gcc-3.0)
# We have to force 64bitness to go search the right libraries
    gcc_64native=no
case "$ccisgcc" in
    $define|true|[Yy])
       echo 'int main(){long l;printf("%d\\n",sizeof(l));}'>try.c
	$cc -o try $ccflags $ldflags try.c
	if [ "`try`" = "8" ]; then
	    cat <<EOM >&4

*** This version of gcc uses 64 bit longs. -Duse64bitall is
*** implicitly set to enable continuation
EOM
	    use64bitall=$define
	    gcc_64native=yes
	    fi
	;;
    esac

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

	case "$ccisgcc" in
	    $define|true|[Yy])
		# For the moment, don't care that it ain't supported (yet)
		# by gcc (up to and including 2.95.3), cause it'll crash
		# anyway. Expect auto-detection of 64-bit enabled gcc on
		# HP-UX soon, including a user-friendly exit
		case $gcc_64native in
		    no) ccflags="$ccflags -mlp64"
			ldflags="$ldflags -Wl,+DD64"
			;;
		    esac
		;;
	    *)
		ccflags="$ccflags +DD64"
		ldflags="$ldflags +DD64"
		;;
	    esac

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

# By setting the deferred flag below, this means that if you run perl
# on a system that does not have the required shared library that you
# linked it with, it will die when you try to access a symbol in the
# (missing) shared library.  If you would rather know at perl startup
# time that you are missing an important shared library, switch the
# comments so that immediate, rather than deferred loading is
# performed.  Even with immediate loading, you can postpone errors for
# undefined (or multiply defined) routines until actual access by
# adding the "nonfatal" option.
# ccdlflags="-Wl,-E -Wl,-B,immediate $ccdlflags"
# ccdlflags="-Wl,-E -Wl,-B,immediate,-B,nonfatal $ccdlflags"
if [ "$gnu_ld" = "yes" ]; then
    ccdlflags="-Wl,-E $ccdlflags"
else
    ccdlflags="-Wl,-E -Wl,-B,deferred $ccdlflags"
    fi


### COMPILER SPECIFICS

## Local restrictions (point to README.hpux to lift these)

## Optimization limits
cat >try.c <<EOF
#include <sys/resource.h>

int main ()
{
    struct rlimit rl;
    int i = getrlimit (RLIMIT_DATA, &rl);
    printf ("%d\n", rl.rlim_cur / (1024 * 1024));
    } /* main */
EOF
$cc -o try $ccflags $ldflags try.c
	maxdsiz=`try`
if [ $maxdsiz -le 64 ]; then
    # 64 Mb is probably not enough to optimize toke.c
    # and regexp.c with -O2
    cat <<EOM >&4
Your kernel limits the data section of your programs to $maxdsiz Mb,
which is (sadly) not enough to fully optimize some parts of the
perl binary. I'll try to use a lower optimization level for
those parts. If you are a sysadmin, and you *do* want full
optimization, raise the 'maxdsiz' kernel configuration parameter
to at least 0x08000000 (128 Mb) and rebuild your kernel.
EOM
regexec_cflags=''
    fi

case "$ccisgcc" in
    $define|true|[Yy])
	
	case "$optimize" in
	    "")           optimize="-g -O" ;;
	    *O[3456789]*) optimize=`echo "$optimize" | sed -e 's/O[3-9]/O2/'` ;;
	    esac
	#ld="$cc"
	ld=/usr/bin/ld
	cccdlflags='-fPIC'
	#lddlflags='-shared'
	lddlflags='-b'
	case "$optimize" in
	    *-g*-O*|*-O*-g*)
		# gcc without gas will not accept -g
		echo "main(){}">try.c
		case "`$cc $optimize -c try.c 2>&1`" in
		    *"-g option disabled"*)
			set `echo "X $optimize " | sed -e 's/ -g / /'`
			shift
			optimize="$*"
			;;
		    esac
		;;
	    esac
	if [ $maxdsiz -le 64 ]; then
	    case "$optimize" in
		*O2*)	opt=`echo "$optimize" | sed -e 's/O2/O1/'`
			toke_cflags="$toke_cflags;optimize=\"$opt\""
			regexec_cflags="optimize=\"$opt\""
			;;
		esac
	    fi
	;;

    *)	# HP's compiler cannot combine -g and -O
	case "$optimize" in
	    "")           optimize="+O2 +Onolimit" ;;
	    *O[3456789]*) optimize=`echo "$optimize" | sed -e 's/O[3-9]/O2/'` ;;
	    esac
	if [ $maxdsiz -le 64 ]; then
	    case "$optimize" in
		*-O*|\
		*O2*)	opt=`echo "$optimize" | sed -e 's/-O/+O2/' -e 's/O2/O1/' -e 's/ *+Onolimit//'`
			toke_cflags="$toke_cflags;optimize=\"$opt\""
			regexec_cflags="optimize=\"$opt\""
			;;
		esac
	    fi
	ld=/usr/bin/ld
	cccdlflags='+Z'
	lddlflags='-b +vnocompatwarnings'
	;;
    esac

## LARGEFILES

#case "$uselargefiles-$ccisgcc" in
#    "$define-$define"|'-define') 
#	cat <<EOM >&4
#
#*** I'm ignoring large files for this build because
#*** I don't know how to do use large files in HP-UX using gcc.
#
#EOM
#	uselargefiles="$undef"
#	;;
#    esac

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
