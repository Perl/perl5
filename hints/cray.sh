case `uname -r` in
6.1*) shellflags="-m+65536" ;;
esac
ccflags="$ccflags -DUNICOS -h nomessage=118:151:172"
usemymalloc='n'
libswanted='malloc m'
d_setregid='undef'
d_setreuid='undef'
