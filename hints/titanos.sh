# Hints file (perl 4.019) for Kubota Pacific's Titan 3000 Series Machines.
# Created by: JT McDuffie (jt@kpc.com)  26 DEC 1991
# p5ed by: Jarkko Hietaniemi <jhi@hut.fi> Aug 27 1994
#  NOTE:   You should run Configure with tcsh (yes, tcsh).
alignbytes="8"
byteorder="4321"
castflags='0'
gidtype='ushort'
groupstype='unsigned short'
intsize='4'
usenm='true'
nm_opt='-eh'
malloctype='void *'
models='none'
ccflags="$ccflags -I/usr/include/net -DDEBUGGING -DSTANDARD_C"
cppflags="$cppflags -I/usr/include/net -DDEBUGGING -DSTANDARD_C"
libs='-lnsl -ldbm -lPW -lmalloc -lm'
stdchar='unsigned char'
static_ext='DynaLoader NDBM_File Socket'
uidtype='ushort'
voidflags='7'
inclwanted='/usr/include /usr/include/net'
libpth='/usr/lib /usr/local/lib /lib'
pth='. /bin /usr/bin /usr/ucb /usr/local/bin /usr/X11/bin /usr/lbin /etc /usr/lib'
