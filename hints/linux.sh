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
# Last updated Tue May 30 14:25:02 EDT 1995
#
# If you wish to use something other than 'gcc' for your compiler,
# you should specify it on the Configure command line.  To use
# gcc-elf, for exmample, type
# ./Configure -Dcc=gcc-elf

# perl goes into the /usr tree.  See the Filesystem Standard
# available via anonymous FTP at tsx-11.mit.edu in
# /pub/linux/docs/linux-standards/fsstnd.
# Allow a command line override, e.g. Configure -Dprefix=/foo/bar
case "$prefix" in
'') prefix='/usr' ;;
esac

# Perl expects BSD style signal handling.
# gcc-2.6.3 defines _G_HAVE_BOOL to 1, but doesn't actually supply bool.
ccflags="-D__USE_BSD_SIGNAL -Dbool=char -DHAS_BOOL $ccflags"

# The following functions are gcc built-ins, but the Configure tests
# may fail because they don't supply proper prototypes.
# This should be fixed as of 5.001f.  I'd appreciate reports.
d_memcmp=define
d_memcpy=define

# Configure may fail to find lstat() since it's a static/inline
# function in <sys/stat.h>.
d_lstat=define

# Explanation?
d_dosuid='define'

# I think Configure gets this right now, but I'd appreciate reports.
malloctype='void *'

# Explanation?
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
else
    cat <<'EOM'

You don't have an ELF gcc.  I will use dld if possible.  If you are
using a version of DLD earlier than 3.2.6, or don't have it at all, you
should probably upgrade. If you are forced to use 3.2.4, you should
uncomment a couple of lines in hints/linux.sh and rerun Configure to
disallow shared libraries.

EOM
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

case "$BASH_VERSION" in
1.14.3*)
    cat <<'EOM'

If you get failure of op/exec test #5 during the test phase, you probably
have a buggy version of bash. Upgrading to a recent version (1.14.4 or
later) should fix the problem.

EOM
;;
esac

# In addition, on some systems there is a problem with perl and NDBM, which
# causes AnyDBM and NDBM_File to lock up. This is evidenced in the tests as
# AnyDBM just freezing.  Currently we disable NDBM for all linux systems.
# If someone can suggest a more robust test, that would be appreciated.
d_dbm_open=undef

