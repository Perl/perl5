#!./perl

print "1..7\n";

$x='banana';
$x=~/.a/g;
if (pos($x)==2) {print "ok 1\n"} else {print "not ok 1\n";}

$x=~/.z/gc;
if (pos($x)==2) {print "ok 2\n"} else {print "not ok 2\n";}

sub f { my $p=$_[0]; return $p }

$x=~/.a/g;
if (f(pos($x))==4) {print "ok 3\n"} else {print "not ok 3\n";}

# Is pos() set inside //g? (bug id 19990615.008)
$x = "test string?"; $x =~ s/\w/pos($x)/eg;
print "not " unless $x eq "0123 5678910?";
print "ok 4\n";

# bug ID 20010704.003
use Tie::Scalar;
tie $y[0], Tie::StdScalar or die $!;
$y[0] = "aaa";
$y[0] =~ /./g;
if (pos($y[0]) == 1) {print "ok 5\n"} else {print "not ok 5\n"}

$x = 0;
$y[0] = "aaa";
$y[$x] =~ /./g;
if (pos($y[$x]) == 1) {print "ok 6\n"} else {print "not ok 6\n"}
untie $y[0];

tie $y{'abc'}, Tie::StdScalar or die $!;
$y{'abc'} = "aaa";
$y{'abc'} =~ /./g;
if (pos($y{'abc'}) == 1) {print "ok 7\n"} else {print "not ok 7\n"}
untie $y{'abc'};
