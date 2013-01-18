# set -x

userelocatableinc='define'

# Having fun with the dlopen check.. :(
#d_dlopen='define'
#d_dlerror='define'


case "$src" in
    /*) run=$src/Cross/run
            targetmkdir=$src/Cross/mkdir
            to=$src/Cross/to
            from=$src/Cross/from
            ;;
    *)  pwd=`test -f ../Configure && cd ..; pwd`
            run=$pwd/Cross/run
            targetmkdir=$pwd/Cross/mkdir
            to=$pwd/Cross/to
            from=$pwd/Cross/from
               ;;
esac
    
targetrun=adb-shell
targetto=adb-push
targetfrom=adb-pull
run=$run-$targetrun
to=$to-$targetto
from=$from-$targetfrom

cat >$run <<EOF
#!/bin/sh
doexit="echo \\\$?"
case "\$1" in
-cwd)
  shift
  cwd=\$1
  shift
  ;;
esac
case "\$cwd" in
'') cwd=$targetdir ;;
esac
exe=\$1
shift
$to \$exe > /dev/null 2>&1

# send copy results to /dev/null as otherwise it outputs speed stats which gets in our way.
foo=\`adb -s $targethost shell "sh -c '(cd \$cwd && \$exe \$@ > \$exe.stdout) ; \$doexit '"\`
# We get back Ok\r\n on android for some reason, grrr:
$from \$exe.stdout
result=\`cat \$exe.stdout\`
rm \$exe.stdout
foo=\`echo \$foo | sed -e 's|\r||g'\`
# Also, adb doesn't exit with the commands exit code, like ssh does, double-grr
echo \$result
exit \$foo
# if test "X\$doexit" != X; then
#  exit \$foo
#else
#  echo \$foo
#fi

EOF
chmod a+rx $run

cat >$targetmkdir <<EOF
#!/bin/sh
adb -s $targethost shell "mkdir -p \$@"
EOF
chmod a+rx $targetmkdir

cat >$to <<EOF
#!/bin/sh
for f in \$@
do
  case "\$f" in
  /*)
    $targetmkdir \`dirname \$f\`
    adb -s $targethost push \$f \$f            || exit 1
    ;;
  *)
    $targetmkdir $targetdir/\`dirname \$f\`
    (adb -s $targethost push \$f $targetdir/\$f < /dev/null 2>&1) || exit 1
    ;;
  esac
done
exit 0
EOF
chmod a+rx $to

cat >$from <<EOF
#!/bin/sh
for f in \$@
do
  $rm -f \$f
  (adb -s $targethost pull $targetdir/\$f . > /dev/null 2>&1) || exit 1
done
exit 0
EOF
chmod a+rx $from

