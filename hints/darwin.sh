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
	# Default install; use non-system directories
	prefix='/usr/local'; # Built-in perl uses /usr
	siteprefix='/usr/local';
	vendorprefix='/usr/local'; usevendorprefix='define';

	# Where to put modules.
	privlib='/Library/Perl'; # Built-in perl uses /System/Library/Perl
	sitelib='/Library/Perl';
	vendorlib='/Network/Library/Perl';
	;;
'/usr')
	# We are building/replacing the built-in perl
	siteprefix='/usr/local';
	vendorprefix='/usr/local'; usevendorprefix='define';

	# Where to put modules.
	privlib='/System/Library/Perl';
	sitelib='/Library/Perl';
	vendorlib='/Network/Library/Perl';
	;;
esac

# 4BSD uses ${prefix}/share/man, not ${prefix}/man.
man1dir="${prefix}/share/man/man1";
man3dir="${prefix}/share/man/man3";

##
# Tool chain settings
##

# Since we can build fat, the archname doesn't need the processor type
archname='darwin';

# nm works.
usenm='true';

# Optimize.
if [ "x$optimize" = 'x' ]; then
    optimize='-O3'
fi

# -pipe: makes compilation go faster.
# -fno-common: we don't like commons.  Common symbols are not allowed
# in MH_DYLIB binaries, which is what libperl.dylib is.  You will fail
# to link without that option, unless you otherwise eliminate all commons
# by, for example, initializing all globals.
# --Fred Sánchez
ccflags="${ccflags} -pipe -fno-common"

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
