#!./perl

# From: kgb@ast.cam.ac.uk (Karl Glazebrook)

print "1..6\n";

srand;

$m=$max=0; 
for(1..1000){ 
   $n = rand(1);
   if ($n<0) {
       print "not ok 1\n# The value of randbits is likely too low in config.sh\n";
       exit
   }
   $m += $n;
   $max = $n if $n > $max;
}
$m=$m/1000;
print "ok 1\n";

$off = log($max)/log(2);
if ($off > 0) { $off = int(.5+$off) }
    else { $off = - int(.5-$off) }
print "# Consider adding $off to randbits\n" if $off > 0;
print "# Consider subtracting ", -$off, " from randbits\n" if $off < 0;

if ($m<0.4) {
    print "not ok 2\n# The value of randbits is likely too high in config.sh\n";
}
elsif ($m>0.6) {
    print "not ok 2\n# The value of randbits is likely too low in config.sh\n";
}else{
    print "ok 2\n";
}

srand;

$m=0; 
for(1..1000){ 
   $n = rand(100);
   if ($n<0 || $n>=100) {
       print "not ok 3\n";
       exit
   }
   $m += $n;

}
$m=$m/1000;
print "ok 3\n";

if ($m<40 || $m>60) {
    print "not ok 4\n";
}else{
    print "ok 4\n";
}

srand(3.14159);
$r = rand;
srand(3.14159);
print "# srand is not consistent.\nnot " if rand != $r;
print "ok 5\n";

print "# rand is unchanging!\nnot " if rand == $r;
print "ok 6\n";

