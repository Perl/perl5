#!./perl

if (! -x '/usr/ucb/groups') {
    print "1..0\n";
    exit 0;
}

print "1..1\n";

for (split(' ', $()) {
    next if $seen{$_}++;
    ($group) = getgrgid($_);
    if (defined $group) {
	push(@gr, $group);
    }
    else {
	push(@gr, $_);
    }
} 
$gr1 = join(' ',sort @gr);
$gr2 = join(' ', sort split(' ',`/usr/ucb/groups`));
#print "gr1 is <$gr1>\n";
#print "gr2 is <$gr2>\n";
print +($gr1 eq $gr2) ? "ok 1\n" : "not ok 1\n";
