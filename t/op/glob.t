#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..10\n";

@oops = @ops = <op/*>;

if ($^O eq 'MSWin32') {
  map { $files{lc($_)}++ } <op/*>;
  map { delete $files{"op/$_"} } split /[\s\n]/, `dir /b /l op & dir /b /l /ah op 2>nul`,
}
else {
  map { $files{$_}++ } <op/*>;
  map { delete $files{$_} } split /[\s\n]/, `echo op/*`;
}
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

# test the "glob" operator
$_ = "op/*";
@glops = glob $_;
print "@glops" eq "@oops" ? "ok 5\n" : "not ok 5\n";

@glops = glob;
print "@glops" eq "@oops" ? "ok 6\n" : "not ok 6\n";

# glob should still work even after the File::Glob stash has gone away
# (this used to dump core)
my $i = 0;
for (1..2) {
    eval "<.>";
    undef %File::Glob::;
    ++$i;
}
print $i == 2 ? "ok 7\n" : "not ok 7\n";

# [ID 20010526.001] localized glob loses value when assigned to

$j=1; %j=(a=>1); @j=(1); local *j=*j; *j = sub{};

print $j    == 1 ? "ok 8\n"  : "not ok 8\n";
print $j{a} == 1 ? "ok 9\n"  : "not ok 9\n";
print $j[0] == 1 ? "ok 10\n" : "not ok 10\n";
