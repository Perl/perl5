#!./perl

# $RCSfile$    
$|  = 1;
$^W = 1;

print "1..9\n";   

# my $file tests

unlink("afile") if -f "afile";     
print "$!\nnot " unless open(my $f,"+>afile");
print "ok 1\n";
binmode $f;
print "not " unless -f "afile";     
print "ok 2\n";
print "not " unless print $f "SomeData\n";
print "ok 3\n";
print "not " unless tell($f) == 9;
print "ok 4\n";
print "not " unless seek($f,0,0);
print "ok 5\n";
$b = <$f>;
print "not " unless $b eq "SomeData\n";
print "ok 6\n";
print "not " unless -f $f;     
print "ok 7\n";
eval  { die "Message" };   
# warn $@;
print "not " unless $@ =~ /<\$f> line 1/;
print "ok 8\n";
print "not " unless close($f);
print "ok 9\n";
unlink("afile");     

