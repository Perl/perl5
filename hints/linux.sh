# hints/linux.sh
# Original version by rsanders
# Additional dlext support by Kenneth Albanowski <kjahds@kjahds.com>
#
# First pass at ELF support by Andy Dougherty <doughera@lafcol.lafayette.edu>
# Fri Feb  3 14:05:00 EST 1995
# Use   sh Configure -Dcc=gcc-elf     to try using gcc-elf.  It might work.
#
# I don't understand several things in here.  Clarifications are welcome.

# Why is this needed?
bin='/usr/bin' 

ccflags='-I/usr/include/bsd'
cppflags=' -I/usr/include/bsd'
d_dosuid='define'

# Why are these needed?
gidtype='gid_t'
groupstype='gid_t'
uidtype='uid_t'

malloctype='void *'
usemymalloc='n'

case "$optimize" in
'') optimize='-O2' ;;
esac

# Why is this needed?
nm_opt=''

sig_name='ZERO HUP INT QUIT ILL TRAP IOT UNUSED FPE KILL USR1 SEGV USR2 PIPE ALRM TERM STKFLT CHLD CONT STOP TSTP TTIN TTOU IO XCPU XFSZ VTALRM PROF WINCH'
signal_t='void'

case "$cc" in
*cc-elf*)
    so='so'
    dlext='so'
    # Configure might not understand nm output for ELF.
    usenm=false
    ;;
*)
    lddlflags='-r'
    so='sa'
    dlext='o'
    ## If you are using DLD 3.2.4 which does not support shared libs,
    ## uncomment the next two lines:
    #ldflags="-static"
    #so='none'
    ;;
esac

cat <<EOM

You should take a look at hints/linux.sh. There are a some lines you
may wish to change near the bottom.
EOM
