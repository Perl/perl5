# hints/amigaos.sh
#
# talk to pueschel@imsdd.meb.uni-bonn.de if you want to change this file.
#
# misc stuff
archname='m68k-amigaos'
cc='gcc'
firstmakefile='GNUmakefile'
usenm='true'

usedl='n'
usemymalloc='n'
usevfork='true'
useperlio='true'
d_eofnblk='define'
d_fork='undef'
d_vfork='define'
groupstype='int'

# libs

libpth="$prefix/lib /local/lib"
glibpth="$libpth"
xlibpth="$libpth"

libswanted='gdbm m'
so=' '

# compiler & linker flags

ccflags='-DAMIGAOS -mstackextend'
ldflags=''
optimize='-O2 -fomit-frame-pointer'

# uncomment the following settings if you are compiling for an 68020+ system

# ccflags='-DAMIGAOS -mstackextend -m68020 -resident32'
# ldflags='-m68020 -resident32'

# uncomment the following line if you want dynamic loading and
# a working version of dld is available

# usedl=''
# ccflags='-DAMIGAOS -mstackextend'
# ldflags=''
# optimize='-O2 -fomit-frame-pointer'
# dlext='o'
# cccdlflags='none'
# ccdlflags='none'
# lddlflags='-oformat a.out-amiga -r'

# Avoid telldir prototype conflict in pp_sys.c  (AmigaOS uses const DIR *)
# Configure should test for this.  Volunteers?
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'
