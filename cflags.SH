case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi 2>/dev/null
    . ./config.sh
    ;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac

also=': '
case $# in
1) also='echo 1>&2 "	  CFLAGS = "'
esac

case $# in
0) set *.c; echo "The current C flags are:" ;;
*) set `echo "$* " | sed 's/\.o /.c /g'`
esac
for file do

    case "$#" in
    1) ;;
    *) echo $n "    $file	$c" ;;
    esac

    case "$file" in
    array.c) ;;
    cmd.c) ;;
    cons.c) ;;
    consarg.c) ;;
    doarg.c) ;;
    doio.c) ;;
    dolist.c) ;;
    dump.c) ;;
    eval.c) ;;
    form.c) ;;
    hash.c) ;;
    malloc.c) ;;
    perl.c) ;;
    perly.c) ;;
    regcomp.c) ;;
    regexec.c) ;;
    stab.c) ;;
    str.c) ;;
    toke.c) ;;
    usersub.c) ;;
    util.c) ;;
    tarray.c) ;;
    tcmd.c) ;;
    tcons.c) ;;
    tconsarg.c) ;;
    tdoarg.c) ;;
    tdoio.c) ;;
    tdolist.c) ;;
    tdump.c) ;;
    teval.c) ;;
    tform.c) ;;
    thash.c) ;;
    tmalloc.c) ;;
    tperl.c) ;;
    tperly.c) ;;
    tregcomp.c) ;;
    tregexec.c) ;;
    tstab.c) ;;
    tstr.c) ;;
    ttoke.c) ;;
    tusersub.c) ;;
    tutil.c) ;;
    *) ;;
    esac

    echo "$ccflags $optimize $large $split"
    eval "$also $ccflags $optimize $large $split"
done
