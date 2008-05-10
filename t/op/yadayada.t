#!./perl

print "1..5\n";

$err = "Unimplemented at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { ... };

print "not " unless $@ eq $err;
print "ok 1\n";
print "# expected: '$err'\n# received: '$@'\n" unless $@ eq $err;

$err = "foo at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { !!! "foo" };

print "not " unless $@ eq $err;
print "ok 2\n";
print "# expected: '$err'\n# received: '$@'\n" unless $@ eq $err;

$err = "Died at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { !!! };

print "not " unless $@ eq $err;
print "ok 3\n";
print "# expected: '$err'\n# received: '$@'\n" unless $@ eq $err;

local $SIG{__WARN__} = sub { $warning = shift };

$err = "bar at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { ??? "bar" };

print "not " unless $warning eq $err;
print "ok 4\n";
print "# expected: '$warning'\n# received: '$warningn" unless $warning eq $err;

$err = "Warning: something's wrong at $0 line " . ( __LINE__ + 2 ) . ".\n";

eval { ??? };

print "not " unless $warning eq $err;
print "ok 5\n";
print "# expected: '$warning'\n# received: '$warningn" unless $warning eq $err;
