case $CONFIG in
'')
    if test ! -f config.sh; then
	ln ../config.sh . || \
	ln ../../config.sh . || \
	ln ../../../config.sh . || \
	(echo "Can't find config.sh."; exit 1)
    fi
    . config.sh
    ;;
esac
case "$0" in
*/*) cd `expr X$0 : 'X\(.*\)/'` ;;
esac
echo "Extracting makedir (with variable substitutions)"
$spitshell >makedir <<!GROK!THIS!
$startsh
# $Header: makedir.SH,v 1.0 87/12/18 13:05:32 root Exp $
# 
# $Log:	makedir.SH,v $
# Revision 1.0  87/12/18  13:05:32  root
# Initial revision
# 
# Revision 4.3.1.1  85/05/10  11:35:14  lwall
# Branch for patches.
# 
# Revision 4.3  85/05/01  11:42:31  lwall
# Baseline for release with 4.3bsd.
# 

export PATH || (echo "OOPS, this isn't sh.  Desperation time.  I will feed myself to sh."; sh \$0; kill \$\$)

case \$# in
  0)
    $echo "makedir pathname filenameflag"
    exit 1
    ;;
esac

: guarantee one slash before 1st component
case \$1 in
  /*) ;;
  *)  set ./\$1 \$2 ;;
esac

: strip last component if it is to be a filename
case X\$2 in
  X1) set \`$echo \$1 | $sed 's:\(.*\)/[^/]*\$:\1:'\` ;;
  *)  set \$1 ;;
esac

: return reasonable status if nothing to be created
if $test -d "\$1" ; then
    exit 0
fi

list=''
while true ; do
    case \$1 in
    */*)
	list="\$1 \$list"
	set \`echo \$1 | $sed 's:\(.*\)/:\1 :'\`
	;;
    *)
	break
	;;
    esac
done

set \$list

for dir do
    $mkdir \$dir >/dev/null 2>&1
done
!GROK!THIS!
$eunicefix makedir
chmod 755 makedir
