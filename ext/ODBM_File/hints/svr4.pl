# Some SVR4 systems may need to link against routines in -lucb for
# odbm.  Some may also need to link against -lc to pick up things like
# ecvt.
$att{LIBS} = ['-ldbm -lucb -lc'];
