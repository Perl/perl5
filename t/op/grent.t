#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = "../lib" if -d "../lib";
    eval { require Config; import Config; };

    my $GR = "/etc/group";

    $where = $GR;

    if (-x "/usr/bin/nidump") {
	if (open(GR, "nidump group . |")) {
	    $where = "NetInfo";
	} else {
	    print "1..0\n";
	    exit 0;
	}
    } elsif ((defined $Config{'i_grp'} and $Config{'i_grp'} ne 'define')
	     or not -f $GR or not open(GR, $GR)
	    ) {
	print "1..0\n";
	exit 0;
    }
}

print "1..1\n";

# Go through at most this many groups.
my $max = 25;

my $n   = 0;
my $tst = 1;
my %suspect;
my %seen;

while (<GR>) {
    chomp;
    my @s = split /:/;
    my ($name_s,$passwd_s,$gid_s,$members_s) = @s;
    if (@s) {
	push @{ $seen{$name_s} }, $.;
    } else {
	warn "# Your $where line $. is empty.\n";
	next;
    }
    next if $n == $max;
    # In principle we could whine if @s != 4 but do we know enough
    # of group file formats everywhere?
    if (@s == 4) {
	$members_s =~ s/\s*,\s*/,/g;
	$members_s =~ s/\s+$//;
	$members_s =~ s/^\s+//;
	@n = getgrgid($gid_s);
	# 'nogroup' et al.
	next unless @n;
	my ($name,$passwd,$gid,$members) = @n;
	# Protect against one-to-many and many-to-one mappings.
	if ($name_s ne $name) {
	    @n = getgrnam($name_s);
	    ($name,$passwd,$gid,$members) = @n;
	    next if $name_s ne $name;
	}
	$members =~ s/\s+/,/g;
	$suspect{$name_s}++
	    if $name    ne $name_s    or
# Shadow passwords confuse this.
# Not that group passwords are used much but better not assume anything.
#              $passwd  ne $passwd_s  or
               $gid     ne $gid_s     or
               $members ne $members_s;
    }
    $n++;
}

# Drop the multiply defined groups.

foreach (sort keys %seen) {
    my $times = @{ $seen{$_} };
    if ($times > 1) {
	# Multiply defined groups are rarely intentional.
	local $" = ", ";
	warn "# Group '$_' defined multiple times in $where, lines: @{$seen{$_}}.\n";
	delete $suspect{$_};
    }
}

print "not " if keys %suspect;
print "ok ", $tst++, "\n";

close(GR);
