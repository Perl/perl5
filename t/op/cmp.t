#!./perl

BEGIN {
       chdir 't' if -d 't';
       @INC = '../lib';
}

# 2s complement assumption. Won't break test, just makes the internals of
# the SVs less interesting if were not on 2s complement system.
my $uv_max = ~0;
my $uv_maxm1 = ~0 ^ 1;
my $uv_big = $uv_max;
$uv_big = ($uv_big - 20000) | 1;
my ($iv0, $iv1, $ivm1, $iv_min, $iv_max, $iv_big, $iv_small);
$iv_max = $uv_max; # Do copy, *then* divide
$iv_max /= 2;
$iv_min = $iv_max;
{
  use integer;
  $iv0 = 2 - 2;
  $iv1 = 3 - 2;
  $ivm1 = 2 - 3;
  $iv_max -= 1;
  $iv_min += 0;
  $iv_big = $iv_max - 3;
  $iv_small = $iv_min + 2;
}
my $uv_bigi = $iv_big;
$uv_bigi |= 0x0;

# Seems one needs to perform the maths on 'Inf' to get the NV correctly primed.
@FOO = ('s', 'N/A', 'a', 'NaN', -1, undef, 0, 1, 3.14, 1e37, 0.632120558, -.5,
	'Inf'+1, '-Inf'-1, 0x0, 0x1, 0x5, 0xFFFFFFFF, $uv_max, $uv_maxm1,
	$uv_big, $uv_bigi, $iv0, $iv1, $ivm1, $iv_min, $iv_max, $iv_big,
	$iv_small);

$expect = 6 * ($#FOO+2) * ($#FOO+1);
print "1..$expect\n";

my $ok = 0;
for my $i (0..$#FOO) {
    for my $j ($i..$#FOO) {
	$ok++;
	# Comparison routines may convert these internally, which would change
	# what is used to determine the comparison on later runs. Hence copy
	my ($i1, $i2, $i3, $i4, $i5, $i6, $i7, $i8, $i9, $i10,
	    $i11, $i12, $i13, $i14, $i15) =
	  ($FOO[$i], $FOO[$i], $FOO[$i], $FOO[$i], $FOO[$i],
	   $FOO[$i], $FOO[$i], $FOO[$i], $FOO[$i], $FOO[$i],
	   $FOO[$i], $FOO[$i], $FOO[$i], $FOO[$i], $FOO[$i]);
	my ($j1, $j2, $j3, $j4, $j5, $j6, $j7, $j8, $j9, $j10,
	    $j11, $j12, $j13, $j14, $j15) =
	  ($FOO[$j], $FOO[$j], $FOO[$j], $FOO[$j], $FOO[$j],
	   $FOO[$j], $FOO[$j], $FOO[$j], $FOO[$j], $FOO[$j],
	   $FOO[$j], $FOO[$j], $FOO[$j], $FOO[$j], $FOO[$j]);
	my $cmp = $i1 <=> $j1;
	if (!defined($cmp) ? !($i2 < $j2)
	    : ($cmp == -1 && $i2 < $j2 ||
	       $cmp == 0  && !($i2 < $j2) ||
	       $cmp == 1  && !($i2 < $j2)))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 <=> $j3) gives: '$cmp' \$i=$i \$j=$j, < disagrees\n";
	}
	$ok++;
	if (!defined($cmp) ? !($i4 == $j4)
	    : ($cmp == -1 && !($i4 == $j4) ||
	       $cmp == 0  && $i4 == $j4 ||
	       $cmp == 1  && !($i4 == $j4)))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 <=> $j3) gives: '$cmp' \$i=$i \$j=$j, == disagrees\n";
	}
	$ok++;
	if (!defined($cmp) ? !($i5 > $j5)
	    : ($cmp == -1 && !($i5 > $j5) ||
	       $cmp == 0  && !($i5 > $j5) ||
	       $cmp == 1  && ($i5 > $j5)))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 <=> $j3) gives: '$cmp' \$i=$i \$j=$j, > disagrees\n";
	}
	$ok++;
	if (!defined($cmp) ? !($i6 >= $j6)
	    : ($cmp == -1 && !($i6 >= $j6) ||
	       $cmp == 0  && $i6 >= $j6 ||
	       $cmp == 1  && $i6 >= $j6))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 <=> $j3) gives: '$cmp' \$i=$i \$j=$j, >= disagrees\n";
	}
	$ok++;
	# OK, so the docs are wrong it seems. NaN != NaN
	if (!defined($cmp) ? ($i7 != $j7)
	    : ($cmp == -1 && $i7 != $j7 ||
	       $cmp == 0  && !($i7 != $j7) ||
	       $cmp == 1  && $i7 != $j7))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 <=> $j3) gives: '$cmp' \$i=$i \$j=$j, != disagrees\n";
	}
	$ok++;
	if (!defined($cmp) ? !($i8 <= $j8)
	    : ($cmp == -1 && $i8 <= $j8 ||
	       $cmp == 0  && $i8 <= $j8 ||
	       $cmp == 1  && !($i8 <= $j8)))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 <=> $j3) gives: '$cmp' \$i=$i \$j=$j, <= disagrees\n";
	}
	$ok++;
	$cmp = $i9 cmp $j9;
	if ($cmp == -1 && $i10 lt $j10 ||
	    $cmp == 0  && !($i10 lt $j10) ||
	    $cmp == 1  && !($i10 lt $j10))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 cmp $j3) gives '$cmp' \$i=$i \$j=$j, lt disagrees\n";
	}
	$ok++;
	if ($cmp == -1 && !($i11 eq $j11) ||
	    $cmp == 0  && ($i11 eq $j11) ||
	    $cmp == 1  && !($i11 eq $j11))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 cmp $j3) gives '$cmp' \$i=$i \$j=$j, eq disagrees\n";
	}
	$ok++;
	if ($cmp == -1 && !($i12 gt $j12) ||
	    $cmp == 0  && !($i12 gt $j12) ||
	    $cmp == 1  && ($i12 gt $j12))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 cmp $j3) gives '$cmp' \$i=$i \$j=$j, gt disagrees\n";
	}
	$ok++;
	if ($cmp == -1 && $i13 le $j13 ||
	    $cmp == 0  && ($i13 le $j13) ||
	    $cmp == 1  && !($i13 le $j13))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 cmp $j3) gives '$cmp' \$i=$i \$j=$j, le disagrees\n";
	}
	$ok++;
	if ($cmp == -1 && ($i14 ne $j14) ||
	    $cmp == 0  && !($i14 ne $j14) ||
	    $cmp == 1  && ($i14 ne $j14))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 cmp $j3) gives '$cmp' \$i=$i \$j=$j, ne disagrees\n";
	}
	$ok++;
	if ($cmp == -1 && !($i15 ge $j15) ||
	    $cmp == 0  && ($i15 ge $j15) ||
	    $cmp == 1  && ($i15 ge $j15))
	{
	    print "ok $ok\n";
	}
	else {
	    print "not ok $ok # ($i3 cmp $j3) gives '$cmp' \$i=$i \$j=$j, ge disagrees\n";
	}
    }
}
