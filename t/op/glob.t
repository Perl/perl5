#!./perl

# $RCSfile: glob.t,v $$Revision: 4.1 $$Date: 92/08/07 18:27:55 $

print "1..4\n";

@ops = <op/*>;

map { $files{$_}++ } <op/*>;
map { delete $files{$_} } split /[\s\n]/, `echo op/*`;
if (keys %files) {
	print "not ok 1\t(",join(' ', sort keys %files),"\n";
} else { print "ok 1\n"; }

print $/ eq "\n" ? "ok 2\n" : "not ok 2\n";

while (<jskdfjskdfj* op/* jskdjfjkosvk*>) {
    $not = "not " unless $_ eq shift @ops;
    $not = "not at all " if $/ eq "\0";
}
print "${not}ok 3\n";

print $/ eq "\n" ? "ok 4\n" : "not ok 4\n";
