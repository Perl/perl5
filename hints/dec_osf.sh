# hints/dec_osf.sh
ccflags="$ccflags -DSTANDARD_C"
lddlflags='-shared -expect_unresolved "*" -s'
