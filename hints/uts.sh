archname='s390'
archobjs='uts/strtol_wrap.o'
cc='cc'
cccdlflags='-pic'
ccflags='-Xa -XTSTRINGS=1500000 -DStrtol=strtol_wrap32 -DStrtoul=strtoul_wrap32'
d_bincompat3='undef'
d_csh='undef' 
d_lstat='define'
d_suidsafe='define'
dlsrc='dl_dlopen.xs'
i_ieeefp='undef'
ld='ld'
lddlflags='-G -z text'
libperl='libperl.so'
libpth='/lib /usr/lib /usr/ccs/lib'
libs='-lsocket -lnsl -ldl -lm'  
libswanted='m'
prefix='/usr/local'
toke_cflags='optimize=""' 
useshrplib='define'

#################################
# Some less routine stuff:
#################################
cc -g -Xa -c -pic -O uts/strtol_wrap.c -o uts/strtol_wrap.o
# Make POSIX a static extension.
cat <<'EOSH' > config.over
static_ext='POSIX B'
dynamic_ext=`echo " $dynamic_ext " |
  sed -e 's/ POSIX / /' -e 's/ B / /'`
EOSH
