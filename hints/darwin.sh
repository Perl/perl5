##
# Darwin (Mac OS) hints
# Wilfredo Sanchez <wsanchez@mit.edu>
##

##
# Paths
##

# Configure hasn't figured out the version number yet.  Bummer.
perl_revision=`awk '/define[ 	]+PERL_REVISION/ {print $3}' $src/patchlevel.h`
perl_version=`awk '/define[ 	]+PERL_VERSION/ {print $3}' $src/patchlevel.h`
perl_subversion=`awk '/define[ 	]+PERL_SUBVERSION/ {print $3}' $src/patchlevel.h`
version="${perl_revision}.${perl_version}.${perl_subversion}"

# BSD paths
case "$prefix" in
  '')
    # Default install; use non-system directories
    prefix='/usr/local'; # Built-in perl uses /usr
    siteprefix='/usr/local';
    vendorprefix='/usr/local'; usevendorprefix='define';

    # Where to put modules.
    privlib="/Library/Perl/${version}"; # Built-in perl uses /System/Library/Perl
    sitelib="/Library/Perl/${version}";
    vendorlib="/Network/Library/Perl/${version}";
    ;;
  '/usr')
    # We are building/replacing the built-in perl
    siteprefix='/usr/local';
    vendorprefix='/usr/local'; usevendorprefix='define';

    # Where to put modules.
    privlib="/System/Library/Perl/${version}";
    sitelib="/Library/Perl/${version}";
    vendorlib="/Network/Library/Perl/${version}";
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

#    Optimizing for size also mean less resident memory usage on the part
# of Perl.  Apple asserts that this is a more important optimization than
# saving on CPU cycles.  Given that memory speed has not increased at
# pace with CPU speed over time (on any platform), this is probably a
# reasonable assertion.
if [ -z "${optimize}" ]; then
  case "$osvers" in
    [12345].*) optimize='-O3' ;;
    *) optimize='-Os' ;;
  esac
fi

# -pipe: makes compilation go faster.
# -fno-common because common symbols are not allowed in MH_DYLIB
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
# This seems to have been fixed since at least Mac OS X 10.1.3,
# stdint.h defining INT32_MIN as (-INT32_MAX-1)
# -- Edward Moy
#
case "$(grep '^#define INT32_MIN' /usr/include/stdint.h)" in
  *-2147483648) ccflags="${ccflags} -DINT32_MIN_BROKEN -DINT64_MIN_BROKEN" ;;
esac

# cppflags='-traditional-cpp';
# Avoid Apple's cpp precompiler, better for extensions
cppflags="${cppflags} -no-cpp-precomp"
# and ccflags needs them as well since we don't use cpp directly
# -- If this is necessary, it's a bug. -wsv
ccflags="${ccflags} -no-cpp-precomp"

# Known optimizer problems.
case "`cc -v 2>&1`" in
  *"3.1 20020105"*) toke_cflags='optimize=""' ;;
esac

# Shared library extension is .dylib.
# Bundle extension is .bundle.
ld='cc';
so='dylib';
dlext='bundle';
dlsrc='dl_dyld.xs'; usedl='define';
cccdlflags=' '; # space, not empty, because otherwise we get -fpic
# Perl bundles do not expect two-level namespace, added in Darwin 1.4.
case "$osvers" in
  1.[0-3].*) ;;
  *) ldflags="${ldflags} -flat_namespace" ;;
esac
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
LANG=C; export LANG;

# Case-insensitive filesystems don't get along with Makefile and
# makefile in the same place.  Since Darwin uses GNU make, this dodges
# the problem.
firstmakefile=GNUmakefile;

#
# The libraries are not threadsafe as of OS X 10.1.
#
# Fix when Apple fixes libc.
#
case "$usethreads$useithreads$use5005threads" in
  *define*)
  case "$osvers" in
    [12345].*)     cat <<EOM >&4



*** Warning, there might be problems with your libraries with
*** regards to threading.  The test ext/threads/t/libc.t is likely
*** to fail.

EOM
    ;;
    *) usereentrant='define';;
  esac

esac
