##
# Darwin (Mac OS) hints
# Wilfredo Sanchez <wsanchez@wsanchez.net>
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
    vendorprefix='/usr'; usevendorprefix='define';

    # Where to put modules.
    sitelib="/Library/Perl/${version}"; # FIXME: Want "/Network/Perl/${version}" also
    vendorlib="/System/Library/Perl/${version}"; # Apple-supplied modules
    ;;

  '/usr')
    # We are building/replacing the built-in perl
    siteprefix='/usr/local';
    vendorprefix='/usr/local'; usevendorprefix='define';

    # Where to put modules.
    sitelib="/Library/Perl/${version}"; # FIXME: Want "/Network/Perl/${version}" also
    vendorlib="/System/Library/Perl/${version}"; # Apple-supplied modules
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

case "$optimize" in
'')
#    Optimizing for size also mean less resident memory usage on the part
# of Perl.  Apple asserts that this is a more important optimization than
# saving on CPU cycles.  Given that memory speed has not increased at
# pace with CPU speed over time (on any platform), this is probably a
# reasonable assertion.
if [ -z "${optimize}" ]; then
  case "`${cc:-gcc} -v 2>&1`" in
    *"gcc version 3."*) optimize='-Os' ;;
    *) optimize='-O3' ;;
  esac
else
  optimize='-O3'
fi
;;
esac

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

# Avoid Apple's cpp precompiler, better for extensions
cppflags="${cppflags} -no-cpp-precomp"

# This is necessary because perl's build system doesn't
# apply cppflags to cc compile lines as it should.
ccflags="${ccflags} ${cppflags}"

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
# But starting from perl 5.8.1/Darwin 7 the default is the two-level.
case "$osvers" in
1.[0-3].*)
   lddlflags="${ldflags} -bundle -undefined suppress"
   ;;
1.*)
   ldflags="${ldflags} -flat_namespace"
   lddlflags="${ldflags} -bundle -undefined suppress"
   ;;
[2-6].*)
   ldflags="${ldflags} -flat_namespace"
   lddlflags="${ldflags} -bundle -undefined suppress"
   ;;
*) lddlflags="${ldflags} -bundle -undefined dynamic_lookup"
   case "$ld" in
   *MACOSX_DEVELOPMENT_TARGET*) ;;
   *) ld="MACOSX_DEPLOYMENT_TARGET=10.3 ${ld}" ;;
   esac
   ;;
esac
ldlibpthname='DYLD_LIBRARY_PATH';
useshrplib='true';

cat > UU/archname.cbu <<'EOCBU'
# This script UU/archname.cbu will get 'called-back' by Configure 
# after it has otherwise determined the architecture name.
case "$ldflags" in
*"-flat_namespace"*) ;; # Backward compat, be flat.
# If we are using two-level namespace, we will munge the archname to show it.
*) archname="${archname}-2level" ;;
esac
EOCBU

##
# System libraries
##

# vfork works
usevfork='true';

# malloc works
usemymalloc='n';

# Locales aren't feeling well.
LC_ALL=C; export LC_ALL;
LANG=C; export LANG;

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

##
# Build process
##

# Case-insensitive filesystems don't get along with Makefile and
# makefile in the same place.  Since Darwin uses GNU make, this dodges
# the problem.
firstmakefile=GNUmakefile;
