#!./perl

$ENV{PATH} = '/usr/xpg4/bin:/bin:/usr/bin:/usr/ucb';

# We have to find a command that prints all (effective
# and real) group names (not ids).  The known commands are:
# groups
# id -Gn
# id -a
# Beware 1: some systems do just 'id -G' even when 'id -Gn' is used.
# Beware 2: id -Gn or id -a format might be id(name) or name(id).
# Beware 3: the groups= might be anywhere in the id output.
#
# That is, we might meet the following:
#
# foo bar zot			# accept
# 1 2 3				# reject
# groups=foo(1),bar(2),zot(3)	# parse
# groups=1(foo),2(bar),3(zot)	# parse
#
# and the groups= might be after, before, or between uid=... and gid=...

GROUPS: {
    last GROUPS if ($groups = `groups 2>/dev/null`) ne '';
    if ($groups = `id -Gn 2>/dev/null` ne '') {
	last GROUPS unless $groups =~ /^(\d+)(\s+\d)*$/;
    }
    if ($groups = `id -a 2>/dev/null` ne '') {
	# Grok format soon.
	last GROUPS;
    }
    # Okay, not today.
    print "1..0\n";
    exit 0;
}

# Remember that group names can contain whitespace, '-', et cetera.
# That is: do not \w, do not \S.
if ($groups =~ /groups=((.+?\(.+?\))(,.+?\(.+?\))*)( [ug]id=|$)/) {
    my $gr = $1;
    my @g0 = $gr =~ /(.+?)\((.+?)\),?/g;
    my @g1 = @g0[ map { $_ * 2     } 0..$#g0/2 ];
    my @g2 = @g0[ map { $_ * 2 + 1 } 0..$#g0/2 ];
    print "# g0 = @g0\n";
    print "# g1 = @g1\n";
    print "# g2 = @g2\n";
    if (grep /\D/, @g1) {
	$groups = join(" ", @g1);
    } elsif (grep /\D/, @g2) {
	$groups = join(" ", @g2);
    } else {
	# Let's fail.  We want to parse the output.  Really.
    }
}

print "1..2\n";

$pwgid = $( + 0;
($pwgnam) = getgrgid($pwgid);
@basegroup{$pwgid,$pwgnam} = (1,1);

$seen{$pwgid}++;

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

if ($^O eq "uwin") { # Or anybody else who can have spaces in group names.
	$gr1 = join(' ', grep(!$did{$_}++, sort split(' ', join(' ', @gr))));
} else {
	$gr1 = join(' ', sort @gr);
}

$gr2 = join(' ', grep(!$basegroup{$_}++, sort split(' ',$groups)));

if ($gr1 eq $gr2) {
    print "ok 1\n";
}
else {
    print "#gr1 is <$gr1>\n";
    print "#gr2 is <$gr2>\n";
    print "not ok 1\n";
}

# multiple 0's indicate GROUPSTYPE is currently long but should be short

if ($pwgid == 0 || $seen{0} < 2) {
    print "ok 2\n";
}
else {
    print "not ok 2 (groupstype should be type short, not long)\n";
}
