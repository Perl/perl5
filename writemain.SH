case $CONFIG in
'')
	if test -f config.sh; then TOP=.;
	elif test -f ../config.sh; then TOP=..;
	elif test -f ../../config.sh; then TOP=../..;
	elif test -f ../../../config.sh; then TOP=../../..;
	elif test -f ../../../../config.sh; then TOP=../../../..;
	else
		echo "Can't find config.sh."; exit 1
	fi
	. $TOP/config.sh
	;;
esac
: This forces SH files to create target in same directory as SH file.
: This is so that make depend always knows where to find SH derivatives.
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting writemain (with variable substitutions)"
: This section of the file will have variable substitutions done on it.
: Move anything that needs config subs from !NO!SUBS! section to !GROK!THIS!.
: Protect any dollar signs and backticks that you do not want interpreted
: by putting a backslash in front.  You may delete these comments.
$spitshell >writemain <<!GROK!THIS!
$startsh
!GROK!THIS!

: In the following dollars and backticks do not need the extra backslash.
$spitshell >>writemain <<'!NO!SUBS!'
: This script takes the plain miniperlmain.c and writes out perlmain.c
: which includes all the extensions.
: The command line arguments name extensions to be used.
:  E.g.:  sh writemain SDBM_File POSIX > perlmain.c
:
args="$*"
if test X"$args" = "X" ; then
    cat miniperlmain.c
else
    sed '/Do not delete this line--writemain depends on it/q' miniperlmain.c
    cat << 'EOP'

#ifdef USE_DYNAMIC_LOADING
    boot_DynamicLoader();
#endif

EOP
    for ext in $args; do
	echo "    newXSUB(\"${ext}::bootstrap\", 0, boot_${ext}, file);"
    done
    echo '}'
fi

!NO!SUBS!
chmod 755 writemain
$eunicefix writemain
