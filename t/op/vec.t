#!./perl

print "1..23\n";

print vec($foo,0,1) == 0 ? "ok 1\n" : "not ok 1\n";
print length($foo) == 0 ? "ok 2\n" : "not ok 2\n";
vec($foo,0,1) = 1;
print length($foo) == 1 ? "ok 3\n" : "not ok 3\n";
print unpack('C',$foo) == 1 ? "ok 4\n" : "not ok 4\n";
print vec($foo,0,1) == 1 ? "ok 5\n" : "not ok 5\n";

print vec($foo,20,1) == 0 ? "ok 6\n" : "not ok 6\n";
vec($foo,20,1) = 1;
print vec($foo,20,1) == 1 ? "ok 7\n" : "not ok 7\n";
print length($foo) == 3 ? "ok 8\n" : "not ok 8\n";
print vec($foo,1,8) == 0 ? "ok 9\n" : "not ok 9\n";
vec($foo,1,8) = 0xf1;
print vec($foo,1,8) == 0xf1 ? "ok 10\n" : "not ok 10\n";
print ((unpack('C',substr($foo,1,1)) & 255) == 0xf1 ? "ok 11\n" : "not ok 11\n");
print vec($foo,2,4) == 1 ? "ok 12\n" : "not ok 12\n";
print vec($foo,3,4) == 15 ? "ok 13\n" : "not ok 13\n";
vec($Vec, 0, 32) = 0xbaddacab;
print $Vec eq "\xba\xdd\xac\xab" ? "ok 14\n" : "not ok 14\n";
print vec($Vec, 0, 32) == 3135089835 ? "ok 15\n" : "not ok 15\n";

# ensure vec() handles numericalness correctly
$foo = $bar = $baz = 0;
vec($foo = 0,0,1) = 1;
vec($bar = 0,1,1) = 1;
$baz = $foo | $bar;
print $foo eq "1" && $foo == 1 ? "ok 16\n" : "not ok 16\n";
print $bar eq "2" && $bar == 2 ? "ok 17\n" : "not ok 17\n";
print "$foo $bar $baz" eq "1 2 3" ? "ok 18\n" : "not ok 18\n";

# error cases

$x = eval { vec $foo, 0, 3 };
print "not " if defined $x or $@ !~ /^Illegal number of bits in vec/;
print "ok 19\n";
$x = eval { vec $foo, 0, 0 };
print "not " if defined $x or $@ !~ /^Illegal number of bits in vec/;
print "ok 20\n";
$x = eval { vec $foo, 0, -13 };
print "not " if defined $x or $@ !~ /^Illegal number of bits in vec/;
print "ok 21\n";
$x = eval { vec($foo, -1, 4) = 2 };
print "not " if defined $x or $@ !~ /^Assigning to negative offset in vec/;
print "ok 22\n";
print "not " if vec('abcd', 7, 8);
print "ok 23\n";
