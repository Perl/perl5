# hints/dec_osf.sh
case "$optimize" in
'') optimize="-g" ;;
esac
ccflags="$ccflags -DSTANDARD_C -DDEBUGGING"
# Version 1 has problems with -no_archive if only an archive
# lib is available.
case "$osvers" in
1*) lddlflags='-shared -expect_unresolved "*" -s' ;;
*)   lddlflags='-shared -no_archive -expect_unresolved "*" -s' ;;
esac
