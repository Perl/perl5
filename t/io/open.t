#!./perl

# $RCSfile$    
$| = 1;

print "1..6\n";

print "$!\nnot " unless open(A,undef);
print "ok 1\n";
print "not " unless print A "SomeData\n";
print "ok 2\n";
print "not " unless tell(A) == 9;
print "ok 3\n";
print "not " unless seek(A,0,0);
print "ok 4\n";
$b = <A>;
print "not " unless $b eq "SomeData\n";
print "ok 5\n";
print "not " unless close(A);
print "ok 6\n";
     

