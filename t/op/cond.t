#!./perl

# $RCSfile: cond.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:41 $

print "1..16\n";

print 1 ? "ok 1\n" : "not ok 1\n";	# compile time
print 0 ? "not ok 2\n" : "ok 2\n";

$x = 1;
print $x ? "ok 3\n" : "not ok 3\n";	# run time
print !$x ? "not ok 4\n" : "ok 4\n";

# Very low precedence between the ? and the :
print $x ? "ok 5\n" or "not ok 5\n" : "not ok 5\n";
# Binds tighter than assignment
$msg = "not ok 6\n" ? "ok 6\n" : "ok 6\n";
print $msg;
# Binds looser than ".."
print "ok ", $x ? 7 : -2..15, "\n";
# Right-associative
print $x ? "ok 8\n" : 0 ? "not ok 8\n" : "not ok 8\n";
# No parens needed when nested like an if-elsif-elsif-elsif-else
$n = 9;
print $n ==  7 ? "not ok 9\n" :
      $n ==  8 ? "not ok 9\n" :
      $n ==  9 ?     "ok 9\n" :
      $n == 10 ? "not ok 9\n" :
      	 	 "not ok 9\n";
# Nor when used like a deeply nested if-else chain
print $n != 7 ?
	$n != 8 ?
	  $n != 9 ?
	    $n != 10 ?
	       "not ok 10\n"
	    :
	       "not ok 10\n"
	  :
	    "ok 10\n"
	:
	  "not ok 10\n"
      :
        "not ok 10\n";
# A random pathologically nested example, which parses like
# $a ? ($b ? ($c ? $d : ($e ? $f : $g)) : $h) : ($i ? $j : $k),
# i.e.,
# if ($a) {
#     if ($b) {
# 	if ($c) {
# 	    $d;
# 	} else {
# 	    if ($e) {
# 		$f;
# 	    } else {
# 		$g;
# 	    }
# 	}
#     } else {
# 	$h;
#     }
# } else {
#     if ($i) {
# 	$j;
#     } else {
# 	$k;
#     }
# }
# We exercise all the branches. The ".5"s should be dont-cares.
($d, $f, $g, $h, $j, $k) =
  ("ok 11\n", "ok 12\n", "ok 13\n", "ok 14\n", "ok 15\n", "ok 16\n");
($a, $b, $c, $e, $i) = (1,  1,  1, .5, .5);
print $a ? $ b ? $c ? $d : $e ? $f : $g : $h : $i ? $j : $k;
($a, $b, $c, $e, $i) = (1,  1,  0,  1, .5);
print $a ? $ b ? $c ? $d : $e ? $f : $g : $h : $i ? $j : $k;
($a, $b, $c, $e, $i) = (1,  1,  0,  0, .5);
print $a ? $ b ? $c ? $d : $e ? $f : $g : $h : $i ? $j : $k;
($a, $b, $c, $e, $i) = (1,  0, .5, .5, .5);
print $a ? $ b ? $c ? $d : $e ? $f : $g : $h : $i ? $j : $k;
($a, $b, $c, $e, $i) = (0, .5, .5, .5,  1);
print $a ? $ b ? $c ? $d : $e ? $f : $g : $h : $i ? $j : $k;
($a, $b, $c, $e, $i) = (0, .5, .5, .5,  0);
print $a ? $ b ? $c ? $d : $e ? $f : $g : $h : $i ? $j : $k;
