# hints/linux.sh
# Original version by rsanders
# Additional support by Kenneth Albanowski <kjahds@kjahds.com>
#
# ELF support by H.J. Lu <hjl@nynexst.com>
# Additional info from Nigel Head <nhead@ESOC.bitnet>
# and Kenneth Albanowski <kjahds@kjahds.com>
#
# Consolidated by Andy Dougherty <doughera@lafcol.lafayette.edu>
#
# Last updated Thu Apr  6 12:22:03 EDT 1995
#
# If you wish to use something other than 'gcc' for your compiler,
# you should specify it on the Configure command line.  To use
# gcc-elf, for exmample, type 
# ./Configure -Dcc=gcc-elf

# perl goes into the /usr tree.  See the Filesystem Standard
# available via anonymous FTP at tsx-11.mit.edu in
# /pub/linux/docs/linux-standards/fsstnd.
# This used to be
# bin='/usr/bin'
# but it doesn't seem sensible to put the binary in /usr and all the
# rest of the support stuff (lib, man pages) into /usr/local.
# However, allow a command line override, e.g. Configure -Dprefix=/foo/bar
case "$prefix" in
'') prefix='/usr' ;;
esac

# Perl expects BSD style signal handling.
# gcc defines _G_HAVE_BOOL to 1, but doesn't actually supply bool.
ccflags="-D__USE_BSD_SIGNAL -Dbool=char -DHAS_BOOL $ccflags"

# The following functions are gcc built-ins, but the Configure tests
# may fail because it doesn't supply a proper prototype.
d_memcmp=define
d_memcpy=define

# Configure may fail to find lstat() since it's a static/inline
# function in <sys/stat.h>.
d_lstat=define

d_dosuid='define'

malloctype='void *'
usemymalloc='n'

case "$optimize" in
'') optimize='-O2' ;;
esac

# Are we using ELF?  Thanks to Kenneth Albanowski <kjahds@kjahds.com>
# for this test.
cat >try.c <<'EOM'
/* Test for whether ELF binaries are produced */
#include <fcntl.h>
#include <stdlib.h>
main() {
	char buffer[4];
	int i=open("a.out",O_RDONLY);
	if(i==-1)
		exit(1); /* fail */
	if(read(i,&buffer[0],4)<4)
		exit(1); /* fail */
	if(buffer[0] != 127 || buffer[1] != 'E' ||
           buffer[2] != 'L' || buffer[3] != 'F')
		exit(1); /* fail */
	exit(0); /* succeed (yes, it's ELF) */
}
EOM
if ${cc:-gcc} try.c >/dev/null 2>&1 && ./a.out; then
    cat <<'EOM'

You appear to have ELF support.  I'll try to use it for dynamic loading.
EOM
    # Configure now handles these automatically.
else
    echo "You don't have an ELF gcc, using dld if available."
    # We might possibly have a version of DLD around.
    lddlflags="-r $lddlflags"
    # These empty values are so that Configure doesn't put in the
    # Linux ELF values.
    ccdlflags=' '
    cccdlflags=' '
    so='sa'
    dlext='o'
    ## If you are using DLD 3.2.4 which does not support shared libs,
    ## uncomment the next two lines:
    #ldflags="-static"
    #so='none'
fi
rm -rf try.c a.out

cat <<'EOM'

You should take a look at hints/linux.sh. There are a some lines you
may wish to change.
EOM

# And -- reported by one user:
# We need to get -lc away from the link lines.
# If we leave it there we get SEGV from miniperl during the build.
# This may have to do with bugs in the pre-release version of libc for ELF.
# Uncomment the next two lines to remove -lc from the link line.
# set `echo " $libswanted " | sed -e 's@ c @ @'`
# libswanted="$*"
