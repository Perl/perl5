##
# Darwin (Mac OS) hints
# Wilfredo Sanchez <wsanchez@mit.edu>
##

##
# Paths
##

# BSD paths
case "$prefix" in
'')	
	prefix='/usr/local'; # Built-in perl uses /usr
	siteprefix='/usr/local';
	vendorprefix='/usr/local'; usevendorprefix='define';

	# 4BSD uses ${prefix}/share/man, not ${prefix}/man.
	# Don't put man pages in ${prefix}/lib; that's goofy.
	man1dir="${prefix}/share/man/man1";
	man3dir="${prefix}/share/man/man3";

	# Where to put modules.
	# Built-in perl uses /System/Library/Perl
	privlib='/Library/Perl';
	sitelib='/Library/Perl';
	vendorlib='/Network/Library/Perl';
	;;
esac

##
# Tool chain settings
##

# Since we can build fat, the archname doesn't need the processor type
archname='darwin';

# nm works.
usenm='true';

# Libc is in libsystem.
#libc='/usr/lib/libSystem.dylib';

# Optimize.
optimize='-O3';

# We have a prototype for telldir.
ccflags="${ccflags} -pipe -fno-common -DHAS_TELLDIR_PROTOTYPE";

# At least on Darwin 1.3.x:
#
# # define INT32_MIN -2147483648
# int main () {
#  double a = INT32_MIN;
#  printf ("INT32_MIN=%g\n", a);
#  return 0;
# }
# will output:
# INT32_MIN=2.14748e+09
# Note that the INT32_MIN has become positive.
# INT32_MIN is set in /usr/include/stdint.h by:
# #define INT32_MIN        -2147483648
# which seems to break the gcc.  Defining INT32_MIN as (-2147483647-1)
# seems to work.  INT64_MIN seems to be similarly broken.
# -- Nicholas Clark, Ken Williams, and Edward Moy
#
ccflags="${ccflags} -DINT32_MIN_BROKEN -DINT64_MIN_BROKEN"

# cpp-precomp is problematic.
cppflags='-traditional-cpp';

# Shared library extension is .dylib.
# Bundle extension is .bundle.
ld='cc';
so='dylib';
dlext='bundle';
dlsrc='dl_dyld.xs'; usedl='define';
cccdlflags=' '; # space, not empty, because otherwise we get -fpic
lddlflags="${ldflags} -bundle -undefined suppress";
ldlibpthname='DYLD_LIBRARY_PATH';
useshrplib='true';

##
# System libraries
##

# vfork works
usevfork='true';

# malloc works
usemymalloc='n';

##
# Build process
##

# Locales aren't feeling well.
LC_ALL=C; export LC_ALL;

# Case-insensitive filesystems don't get along with Makefile and
# makefile in the same place.  Since Darwin uses GNU make, this dodges
# the problem.
firstmakefile=GNUmakefile;
