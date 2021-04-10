#!./perl

# t/base/pat.t - check base regex for $_

print "1..2\n";

# First test to see if we can run the tests.

$_ = 'test';
/^test/
  ? ( print "ok 1 - match regex\n" )
  : ( print "not ok 1 - match regex\n" );

/^foo/
  ? ( print "not ok 2 - match regex\n" )
  : ( print "ok 2 - match regex\n" );
