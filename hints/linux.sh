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
# Updated Tue May 30 14:25:02 EDT 1995
# Add ability to use command-line overrides for optinal settings.

# perl goes into the /usr tree.  See the Filesystem Standard
# available via anonymous FTP at tsx-11.mit.edu in
# /pub/linux/docs/linux-standards/fsstnd.
# Allow a command line override, e.g. Configure -Dprefix=/foo/bar
case "$prefix" in
'') prefix='/usr' ;;
esac

# Perl users typically expect BSD style signal handling.
# This may not be needed in 5.002 since sigaction is used.
# gcc-2.6.3 defines _G_HAVE_BOOL to 1, but doesn't actually supply bool.
ccflags="-D__USE_BSD_SIGNAL -Dbool=char -DHAS_BOOL $ccflags"

# Configure may fail to find lstat() since it's a static/inline
# function in <sys/stat.h>.
d_lstat=define

# Explanation?
case "$d_dosuid" in
'') d_dosuid='define' ;;
esac

# I think Configure gets this right now, but I'd appreciate reports.
malloctype='void *'

# Explanation?
case "$usemymalloc" in
'') usemymalloc='n' ;;
esac

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
uncomment a couple of lines in hints/linux.sh and restart Configure so
that shared libraries will be disallowed.

EOM
    lddlflags="-r $lddlflags"
    # These empty values are so that Configure doesn't put in the
    # Linux ELF values.
    ccdlflags=' '
    cccdlflags=' '
    ccflags="-DOVR_DBL_DIG=14 $ccflags"
    so='sa'
    dlext='o'
    ## If you are using DLD 3.2.4 which does not support shared libs,
    ## uncomment the next two lines:
    #ldflags="-static"
    #so='none'
fi

rm -f try.c a.out

if /bin/bash -c exit; then
  echo You appear to have a working bash. Good.
else
  cat << 'EOM'
Warning: it would appear you have a defective bash shell installed. This is
likely to give you a failure of op/exec test #5 during the test phase of the
build, Upgrading to a recent version (1.14.4 or later) should fix the
problem.

EOM

fi

# In addition, on some systems there is a problem with perl and NDBM, which
# causes AnyDBM and NDBM_File to lock up. This is evidenced in the tests as
# AnyDBM just freezing.  Currently we disable NDBM for all linux systems.
# If someone can suggest a more robust test, that would be appreciated.
# This will generate a harmless message:
# Hmm...You had some extra variables I don't know about...I'll try to keep 'em.
#	Propagating recommended variable d_dbm_open
case "$d_dbm_open" in
'') d_dbm_open=undef ;;
esac

