# hints/amigaos.sh
#
# talk to pueschel@imsdd.meb.uni-bonn.de if you want to change this file.
#
# misc stuff
archname='m68k-amigaos'
cc='gcc'
firstmakefile='GNUmakefile'
ccflags='-DAMIGAOS -mstackextend'
optimize='-O2 -fomit-frame-pointer'

cppminus=' '
cpprun='cpp'
cppstdin='cpp'

usenm='y'
usemymalloc='n'
usevfork='true'
useperlio='true'
d_eofnblk='define'
d_fork='undef'
d_vfork='define'
groupstype='int'

# libs

libpth="/local/lib $prefix/lib"
glibpth="$libpth"
xlibpth="$libpth"

libswanted='dld m c gdbm'
so=' '

# dynamic loading

dlext='o'
cccdlflags='none'
ccdlflags='none'
lddlflags='-oformat a.out-amiga -r'

# Avoid telldir prototype conflict in pp_sys.c  (AmigaOS uses const DIR *)
# Configure should test for this.  Volunteers?
pp_sys_cflags='ccflags="$ccflags -DHAS_TELLDIR_PROTOTYPE"'
