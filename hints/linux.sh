# Configuration time: Mon May 16 03:41:24 EDT 1994
# Original version by rsanders
# Additional dlext support by Kenneth Albanowski <kjahds@kjahds.com>
# Target system: linux hrothgar 1.1.12 #9 sat may 14 02:03:23 edt 1994 i486 
bin='/usr/bin' 
ccflags='-I/usr/include/bsd'
cppflags=' -I/usr/include/bsd'
d_dosuid='define'
d_voidsig='define'
gidtype='gid_t'
groupstype='gid_t'
malloctype='void *'
nm_opt=''
optimize='-O2'
sig_name='ZERO HUP INT QUIT ILL TRAP IOT UNUSED FPE KILL USR1 SEGV USR2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH'
signal_t='void'
uidtype='uid_t'
usemymalloc='n'
yacc='bison -y'
lddlflags='-r'
so='sa'
dlext='o'
## If you are using DLD 3.2.4 which does not support shared libs,
## uncomment the next two lines:
#ldflags="-static"
#so='none'

cat <<EOM

You should take a look at hints/linux.sh. There are a couple of lines you
may wish to change near the bottom.
EOM
