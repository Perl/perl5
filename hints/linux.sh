# hints/linux.sh
# Original version by rsanders
# Additional support by Kenneth Albanowski <kjahds@kjahds.com>
#
# First pass at ELF support by Andy Dougherty <doughera@lafcol.lafayette.edu>
# Fri Feb  3 14:05:00 EST 1995
# Use   sh Configure -Dcc=gcc-elf     to try using gcc-elf.  It might work.
#
# Last updated Mon Mar  6 10:18:10 EST 1995
#

# Why is this needed?
bin='/usr/bin'

# Apparently some versions of gcc 2.6.2 are picking up _G_HAVE_BOOL
# from somewhere (_G_config.h maybe?) but not actually defining bool.
# Anyone really know what's going on?
ccflags='-Dbool=char -DHAS_BOOL'

d_dosuid='define'

malloctype='void *'
usemymalloc='n'

case "$optimize" in
'') optimize='-O2' ;;
esac

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
