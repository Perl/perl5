# hints/os390.sh
#
# OS/390 hints by David J. Fiander <davidf@mks.com>
#
# OS/390 OpenEdition Release 3 Mon Sep 22 1997 thanks to:
#
#     John Goodyear <johngood@us.ibm.com>
#     John Pfuntner <pfuntner@vnet.ibm.com>
#     Len Johnson <lenjay@ibm.net>
#     Bud Huff  <BAHUFF@us.oracle.com>
#     Peter Prymmer <pvhp@forte.com>
#     Andy Dougherty  <doughera@lafayette.edu>
#     Tim Bunce  <Tim.Bunce@ig.co.uk>
#
#  as well as the authors of the aix.sh file
#

# It is too late in Configure by the time this is called to change the
# compiler.  But xlc or synonyms are the only thing that likely currently will
# work.
#
# But it isn't too late to change 'ld', and the z/OS 390 ld command doesn't
# understand some command line options like -W and -q that the loader needs to
# know about.  xlc also acts like a loader and does understand them.
case "$ld" in
'') ld='xlc' ;;
esac

# khw thinks these -W options are obsolete, at least the -Wc, where the 'c'
# indicates it goes to the compiler.  It appears that since these were written,
# IBM added the -q series of options to the compiler, which khw thinks should
# be sufficient.  -Wl are for the loader, and may be required.
os390_Wc="-Wc"
os390_Wl="-Wl"

# -DEBCDIC should come from Configure and need not be mentioned here.
# Prepend your favorites with Configure -Dccflags=your_favorites

# This overrides the name the compiler was called with.  'ext' is required for
# "unicode literals" to be enabled
def_os390_cflags='-qlanglvl=extc99';

def_os390_cflags="$def_os390_cflags -qlongname";    # khw thinks this is obsolete
def_os390_cflags="$def_os390_cflags -qfloat=ieee";  # khw thinks this is obsolete

# xplink = eXtended Performance linking: "Uses a z/OS linkage specifically
# designed to increase performance."
def_os390_cflags="$def_os390_cflags -qxplink";
def_os390_cccdlflags="-qxplink"
def_os390_ldflags="-qxplink"
os390_Wc="$os390_Wc,XPLINK"
os390_Wl="$os390_Wl,XPLINK"

# Without this, you get "IEW2689W 4C40 DEFINITION SIDE FILE IS NOT DEFINED."
os390_Wl="$os390_Wl,dll"

# Exports all externally defined functions and variables in the compilation
# unit so that a DLL application can use them."
def_os390_cflags="$def_os390_cflags -qexportall";
def_os390_cccdlflags="$def_os390_cccdlflags -qexportall"
os390_Wc="$os390_Wc,EXPORTALL"

# 3296= #include file not found;
# 4108= The use of keyword &1 is non-portable
#       We care about this because it
#       actually means it didn't do what we expected. e.g.,
#          INFORMATIONAL CCN4108 ./proto.h:4534 The use of keyword '__attribute__' is non-portable.
def_os390_cflags="$def_os390_cflags -qhaltonmsg=3296:4108"

# Combinte the -W flags with the rest
def_os390_cflags="$def_os390_cflags $os390_Wc";
def_os390_cflags="$def_os390_cflags $os390_Wl";

def_os390_cccdlflags="$def_os390_cccdlflags $os390_Wc";
def_os390_cccdlflags="$def_os390_cccdlflags $os390_Wl";

def_os390_defs='-DMAXSIG=39';               # maximum signal number; not furnished by IBM
def_os390_defs="$def_os390_defs -DOEMVS";   # is used in place of #ifdef __MVS__

# Turn on POSIX compatibility modes
#  https://www.ibm.com/support/knowledgecenter/SSLTBW_2.4.0/com.ibm.zos.v2r4.bpxbd00/ftms.htm
def_os390_defs="$def_os390_defs -D_ALL_SOURCE";

# defines a BSD-like socket interface for the function prototypes and structures involved
def_os390_defs="$def_os390_defs -D_OE_SOCKETS";

# ensure that the OS/390 yacc generated parser is reentrant.
def_os390_defs="$def_os390_defs -DYYDYNAMIC";

# LC_MESSAGES only affects the yes/no strings in langinfo; not the things we
# expect it to
def_os390_defs="$def_os390_defs -DNO_LOCALE_MESSAGES"

# Combine -D with cflags
case "$ccflags" in
'') ccflags="$def_os390_cflags $def_os390_defs"  ;;
*)  ccflags="$ccflags $def_os390_cflags $def_os390_defs" ;;
esac

# Turning on optimization causes perl to not even compile from miniperl.  You
# can override this with Configure -Doptimize='-O2' or somesuch.
case "$optimize" in
'') optimize=' ' ;;
esac

# To link via definition side decks we need the dll option
# You can override this with Configure -Ucccdlflags or somesuch.
case "$cccdlflags" in
'') cccdlflags=$def_os390_cccdlflags;;
esac

case "$so" in
'') so='a' ;;
esac

case "$alignbytes" in
'') alignbytes=8 ;;
esac

case "$usemymalloc" in
'') usemymalloc='n' ;;
esac

# On OS/390, libc.a doesn't really hold anything at all,
# so running nm on it is pretty useless.
# You can override this with Configure -Dusenm.
case "$usenm" in
'') usenm='false' ;;
esac

case "$ldflags" in
'') ldflags="$def_os390_ldflags $os390_Wl";;
esac

# Setting ldflags='-Wl,EDIT=NO' will get rid of the symbol
# information at the end of the executable (=> smaller binaries).
# Override this option with -Dldflags='whatever else you wanted'.
case "$optimize" in
*-g*) ;;
*)  ldflags="$ldflags -Wl,EDIT=NO"
esac

# In order to build with dynamic be sure to specify:
#   Configure -Dusedl
# Do not forget to add $archlibexp/CORE to your LIBPATH.
# You might want to override some of this with things like:
#  Configure -Dusedl -Ddlext=so -Ddlsrc=dl_dllload.xs.
case "$usedl" in
'')
   usedl='n'
   case "$dlext" in
   '') dlext='none' ;;
   esac
   ;;
define)
   case "$useshrplib" in
   '') useshrplib='true' ;;
   esac
   case "$dlsrc" in
   '') dlsrc='dl_dllload.xs' ;;
   esac
   # For performance use 'so' at or beyond v2.8, 'dll' for 2.7 and prior versions
   case "`uname -v`x`uname -r`" in
   02x0[89].*|02x1[0-9].*|[0-9][3-9]x*)
       so='so'
       case "$dlext" in
       '') dlext='so' ;;
       esac
       ;;
   *)
       so='dll'
       case "$dlext" in
       '') dlext='dll' ;;
       esac
       ;;
   esac
   libperl="libperl.$so"

   # Allows char **environ to be accessed from a dynamically loaded
   # module such as a DLL
   ccflags="$ccflags -D_SHR_ENVIRON"

   cccdlflags="-c $def_os390_cccdlflags"
   lddlflags="$def_os390_cccdlflags"

   # The following will need to be modified for the installed libperl.x.
   # The modification to Config.pm is done by the installperl script after the
   # build and test.  These are written to a CBU so that the libperl.x file
   # comes after all the dash-options in the flags.  Configure takes the
   # lddlflags we give it and looks for paths to libraries to append -L options
   # to lddlflags.  But this causes the file libperl.x to appear in the final
   # command line after the -L options.  And z/OS doesn't like filenames after
   # options.  This CBU defers the adding of libperl.x until after any munging
   # that Configure does.
   cat >config.arch <<'	EOCBU'
	case "ccdlflags" in
	'') ccdlflags="`pwd`/libperl.x" ;;
	 *) ccdlflags="$ccdlflags `pwd`/libperl.x" ;;
	esac
	lddlflags="$lddlflags `pwd`/libperl.x"
	EOCBU
   ;;
esac

# even on static builds using LIBPATH should be OK.
case "$ldlibpthname" in
'') ldlibpthname=LIBPATH ;;
esac

# The following should always be used.  Perhaps newer threads will work, but
# when khw tried, other things would have had to be changed to get it to work,
# so left as-is.
d_oldpthreads='define'

# Header files to include.
# You can override these with Configure -Ui_time -Ui_systime -Dd_pthread_atfork.
case "$i_time" in
'') i_time='define' ;;
esac
case "$i_systime" in
'') i_systime='define' ;;
esac
case "$d_pthread_atfork" in
'') d_pthread_atfork='undef' ;;
esac

# (from aix.sh)
# uname -m output is too specific and not appropriate here
# osname should come from Configure
# You can override this with Configure -Darchname='s390' but please don't.
case "$archname" in
'') archname="$osname" ;;
esac

# We have our own cppstdin script.  This is not a variable since
# Configure sees the presence of the script file.
# We put system header -D definitions in so that Configure
# can find the shmat() prototype in <sys/shm.h> and various
# other things.  Unfortunately, cppflags occurs too late to be of
# value external to the script.  This may need to be revisited
#
# khw believes some of this is obsolete.  DOLLARINNAMES allows '$' in variable
# names, for whatever reason
# NOLOC says to use the 1047 code page, and no locale
case "$usedl" in
define)
echo 'cat >.$$.c; '"$cc"' -D_OE_SOCKETS -D_ALL_SOURCE -D_SHR_ENVIRON -E -Wc,"LANGLVL(DOLLARINNAMES)",NOLOC ${1+"$@"} .$$.c | fgrep -v "??="; rm .$$.c' > cppstdin
   ;;
*)
echo 'cat >.$$.c; '"$cc"' -D_OE_SOCKETS -D_ALL_SOURCE -E -Wc,"LANGLVL(DOLLARINNAMES)",NOLOC ${1+"$@"} .$$.c | fgrep -v "??="; rm .$$.c' > cppstdin
   ;;
esac

#
# Note that Makefile.SH employs a bare yacc command to generate
# perly.[hc], hence you may wish to:
#
#    alias yacc='myyacc'
#
# Then if you would like to use myyacc and skip past the
# following warnings try invoking Configure like so:
#
#    sh Configure -Dbyacc=yacc
#
# This trick ought to work even if your yacc is byacc.
#
if test "X$byacc" = "Xbyacc" ; then
   if test -e /etc/yyparse.c ; then
       : we should be OK - perhaps do a test -r?
   else
       cat <<EOWARN >&4

Warning.  You do not have a copy of yyparse.c, the default
yacc parser template file, in place in /etc.
EOWARN
       if test -e /samples/yyparse.c ; then
           cat <<EOWARN >&4

There does appear to be a template file in /samples though.
Please run:

     cp /samples/yyparse.c /etc

before attempting to Configure the build of $package.

EOWARN
       else
           cat <<EOWARN >&4

There does not appear to be one in /samples either.
If you feel you can make use of an alternate yacc-like
parser generator then please read the comments in the
hints/os390.sh file carefully.

EOWARN
       fi
       exit 1
   fi
fi

# These exist, but there is something wrong with either them, or our reentr.[ch],
# and no one has felt it important enough to investigate/fix.  The
# non-reentrant versions seem to work, but will have races in threads.
d_gethostbyaddr_r='undef'
d_gethostbyname_r='undef'
d_gethostent_r='undef'

# nan() used to not work as expected: nan("") or nan("0") returned zero, not a
# nan.  This may have been a C89 issue.
# http://www-01.ibm.com/support/knowledgecenter/SSLTBW_1.12.0/com.ibm.zos.r12.bpxbd00/nan.htm%23nan?lang=en
#d_nan='undef'

# Configure says this exists, but it doesn't work properly.  See
# <54DCE073.4010100@khwilliamson.com>
d_dir_dd_fd='undef'

############################################################################
# Thread support
# use Configure -Dusethreads to enable
# This script UU/usethreads.cbu will get 'called-back' by Configure
# after it has prompted the user for whether to use threads.
# setlocale() returns NULL if a thread has been created, so we can't use it
# generally.  (It would be possible to have it work for initialization, so that
# the user could specify a locale for the whole program; but deferring doing
# that work until someone wants it)  Maybe IBM will support POSIX 2008 at some
# point.  There are hooks that make it look like they were working on it.
cat > UU/usethreads.cbu <<'EOCBU'
case "$usethreads" in
$define|true|[yY]*)
   echo "Your system's setlocale() is broken under threads; marking it as unavailable" >&4
   d_setlocale="undef"
   d_setlocale_accepts_any_locale_name="undef"
   d_has_C_UTF8="false"
esac
EOCBU
