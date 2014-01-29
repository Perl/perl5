# Cross-compiling from Linux to mingw64

# Example using wine:
# ./Configure -des -Dusedevel -DDEBUGGING -Dusecrosscompile -Dtargetarch=x86_64-w64-mingw32 -Dcc=gcc.exe -Dtargetrun=wine -Dsysroot=$MINGW64_SYSROOT -Accflags=" -I$MINGW64_SYSROOT/../include " -Aar=ar.exe -Aranlib=ranlib.exe -Anm=nm.exe -Ald=gcc.exe

osname="MSWin32"

usethreads="$define"
useithreads="$define"
useshrplib="$define"
use64bitint="$define"
uselargefiles="$define"

# To pass locale tests
case "$targetenv" in
''|*\&)
    targetenv="$targetenv set PERL_BADLANG=0 &"
;;
*)
    targetenv="$targetenv & set PERL_BADLANG=0 &"
;;
esac

# No csh
d_csh='undef'
# Configure test doesn't work when cross-compiling to non-unix
fflushNULL='define'

_exe='.exe'

startperl='#!perl'

targetsh='cmd /x /c'

# Win32-specific flags
ccflags="$ccflags -DWIN32 -DWIN64 -DCONSERVATIVE  -DPERL_TEXTMODE_SCRIPTS -DPERL_IMPLICIT_CONTEXT -DPERL_IMPLICIT_SYS"
# Should this be here?
ccflags="$ccflags -DPERLDLL"
ccflags="$ccflags -mms-bitfields"
# Add win32/include to the search path
ccflags="$ccflags -I$src -I$src/win32 -I$src/win32/include "
cppflags="$cppflags $ccflags"
libswanted='net socket inet nsl nm ndbm gdbm dbm db malloc dl ld sun m c cposix posix ndir dir crypt ucb bsd BSD PW x msvcrt ws2_32 wsock32 comctl32 mingw32 mingw64 uuid moldname kernel32 user32 gdi32 winspool comdlg32 advapi32 shell32 ole32 oleaut32 netapi32 mpr winmm version odbc32 odbccp32'

lddlflags="$lddlflags -mdll"
dlext='dll'
so='dll'
dlsrc='dl_win32.xs'

dlltool='dlltool.exe'

# Do we need this?
#ldflags="$ldflags -static -static-libgcc -static-libstdc++"

archobjs="win32.o win32sck.o win32thread.o fcrypt.o win32io.o"

path_sep=';'

# Defined in win32/
d_alarm='define'
d_crypt='define'

d_readdir='define'
d_rewinddir='define'
d_seekdir='define'
d_closedir='define'
d_telldir='define'
d_telldirproto='define'

d_flock='define'
d_flockproto='define'

d_gettimeod='define'
d_killpg='define'
d_link='define'
d_pause='define'
d_pipe='define'
d_pseudofork='define'

d_sin6_scope_id='define'

d_snprintf='define'
d_vsnprintf='define'

d_times='define'
d_uname='define'
d_union_semun='define'
d_waitpid='define'

d_gethbyaddr='define'
d_gethbyname='define'
d_gethname='define'
d_gethostprotos='define'
d_getlogin='define'
d_getpbyname='define'
d_getpbynumber='define'
d_getprotoprotos='define'
d_getsbyname='define'
d_getsbyport='define'
d_getservprotos='define'

# Defined in config_sh.PL
d_atoll='define'
d_strtoll='define'
d_strtoull='define'

# Configure says undef, win32/config.gc says define
d_casti32='define'
d_fds_bits='define'
i_fcntl='define'
o_nonblock='O_NONBLOCK'

# These are defined in msvcrt.a but we don't have wrappers for them
d_inetntop='undef'
d_inetpton='undef'

# WIP


# Why isn't Configure finding the proper values here?
d_dlerror='define'
d_dlopen='define'

# /WIP

# This script UU/archname.cbu will get 'called-back' by Configure.
$cat > UU/archname.cbu <<'EOCBU'
# Configure lowercases osname after the hints files
# are run, so we work around it here.
osname="MSWin32"
EOCBU

pwd=''
case "$src" in
    /*) pwd="$src"
            ;;
    *)  pwd=`test -f ../Configure && cd ..; pwd`
            ;;
esac

cp $pwd/win32/*.[ch] $pwd/
cp $pwd/win32/FindExt.pm $pwd/lib/
mkdir $pwd/lib/CORE/
cp $pwd/*.h $pwd/lib/CORE/
cp -pR $pwd/win32/include/* $pwd/lib/CORE/

$cat <<'EOO' >> $pwd/config.arch
# Why isn't Configure getting most of these right?
ivsize='8'
ivtype='long long'

ptrsize='8'

lseeksize='8'
lseektype='long long'

ssizetype='long long'
st_ino_size='8'

uvsize='8'
uvtype='unsigned long long'

# Configure will set these to %lld and sosuch, but warn everywhere/die
ivdformat='"I64d"'
uvXUformat='"I64X"'
uvoformat='"I64o"'
uvuformat='"I64u"'
uvxformat='"I64x"'

clocktype='clock_t'
db_hashtype='int'
db_prefixtype='int'
groupstype='gid_t'
i8type='char'
netdb_hlen_type='int'
netdb_host_type='char *'
netdb_name_type='char *'
pidtype='int'
selecttype='Perl_fd_set *'
shmattype='void *'

uidformat='"ld"'
uidsign='-1'
uidsize='4'
uidtype='uid_t'

gidformat='"ld"'
gidsign='-1'
gidsize='4'
gidtype='gid_t'

sig_count='26'
sig_name='ZERO HUP INT QUIT ILL NUM05 NUM06 NUM07 FPE KILL NUM10 SEGV NUM12 PIPE ALRM TERM NUM16 NUM17 NUM18 NUM19 CHLD BREAK ABRT STOP NUM24 CONT CLD'
sig_name_init='"ZERO", "HUP", "INT", "QUIT", "ILL", "NUM05", "NUM06", "NUM07", "FPE", "KILL", "NUM10", "SEGV", "NUM12", "PIPE", "ALRM", "TERM", "NUM16", "NUM17", "NUM18", "NUM19", "CHLD", "BREAK", "ABRT", "STOP", "NUM24", "CONT", "CLD", 0'
sig_num='0 1 2 21 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 20'
sig_num_init='0, 1, 2, 21, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 20, 0'
sig_size='27'
signal_t='void'

EOO

. $pwd/config.arch

$cat <<'EOO' >> $pwd/config.arch

extensions="$extensions Win32 Win32API/File Win32CORE"
dynamic_ext="$dynamic_ext Win32 Win32API/File"
static_ext="$static_ext Win32CORE"
EOO

case "$targetrun" in
*ssh*)

unix_to_dos=$pwd/Cross/unix_to_dos
run_ssh_bat=$pwd/Cross/run-ssh.bat

cat >$unix_to_dos <<EOF
#!/bin/sh
echo \$@ | $tr '/' '\\\\'
EOF
$chmod a+rx $unix_to_dos

cat >$run <<EOF
#!/bin/sh
env=''
case "\$1" in
-cwd)
  shift
  cwd=\$1
  shift
  ;;
esac
case "\$1" in
-env)
  shift
  env=\$1
  shift
  ;;
esac
case "\$cwd" in
'') cwd=$targetdir ;;
esac
exe=\$1
shift

if $test ! -e \$exe -a -e "\$exe.exe"; then
    exe="\$exe.exe"
fi

$to \$exe

exe=\`$unix_to_dos \$exe\`
cwd=\`$unix_to_dos \$cwd\`

env=\`echo "\$env" | $sed -s 's/LD_LIBRARY_//g' | $sed -e 's/:.PATH$/:%PATH%/' | $tr ':' ';'\`

if test "X\$env" != X; then
    env="\$env &"
fi

$targetrun -p $targetport -l $targetuser $targethost "cd \$cwd & \$env .\\run-ssh.bat \$exe \$@" | $tr -d '\r'

$from output.status 2>/dev/null
if $test -e output.status; then
    result_status=\`$cat output.status\`
    result_status=\`echo \$result_status | $tr -d '\r'\`
    rm output.status
else
    result_status=0
fi

exit \$result_status
EOF
$chmod a+rx $run

cat >$targetmkdir <<EOF
#!/bin/sh
for file in \$@; do
    dir=\$file
    if test -f \$file; then
        dir=\`dirname \$file\`
    fi
    base='`$unix_to_dos $targetdir`';
    for d in \`echo \$dir | tr '/' ' '\`; do
        base="\$base\\\\\$d";
        $targetrun -p $targetport -l $targetuser $targethost "cd $targetdir && mkdir \$base" 2>/dev/null
    done
done;
EOF
$chmod a+rx $targetmkdir

cat >$to <<EOF
#!/bin/sh
for f in \$@
do
  case "\$f" in
  *)
    if $test ! -e \$f -a -e "\$f.exe"; then
        f="\$f.exe"
    fi
    end=''
    case \$f in
        ./*)
            nostart=\`echo \$f | sed 's:^..::'\`
            end="$targetdir/\$nostart"
            $targetmkdir \$nostart
            ;;
        *)
            end="$targetdir/\$f"
            $targetmkdir \$f
            ;;
    esac
    case "\$f" in
    */*) if test "X\`dirname \$f\`" != "X."; then
            end=\`dirname \$end\`
         fi
    esac
    $targetto -P $targetport -r $q \$f $targetuser@$targethost:\$end  2>/dev/null || exit 1
    ;;
  esac
done
exit 0
EOF
$chmod a+rx $to

cat >run-ssh.bat <<EOF
@echo off
setlocal ENABLEDELAYEDEXPANSION
call %*
echo %ERRORLEVEL% > output.status
endlocal
EOF
$chmod a+rx run-ssh.bat
$to run-ssh.bat 2>/dev/null

esac