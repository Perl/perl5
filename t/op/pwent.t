#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = "../lib" if -d "../lib";
    eval { require Config; import Config; };

    my $PW = "/etc/passwd";

    $where = $PW;

    if (-x "/usr/bin/nidump") {
	if (open(PW, "nidump passwd . |")) {
	    $where = "NetInfo";
	} else {
	    print "1..0\n";
	    exit 0;
	}
    } elsif ((defined $Config{'i_pwd'} and $Config{'i_pwd'} ne 'define')
	     or not -f $PW or not open(PW, $PW)) {
	print "1..0\n";
	exit 0;
    }
}

print "1..1\n";

# Go through at most this many users.
my $max = 25; #

my $n = 0;
my $tst = 1;
my %suspect;
my %seen;

while (<PW>) {
    chomp;
    my @s = split /:/;
    my ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s;
    if (@s) {
	push @{ $seen{$name_s} }, $.;
    } else {
	warn "# Your $where line $. is empty.\n";
	next;
    }
    next if $n == $max;
    # In principle we could whine if @s != 7 but do we know enough
    # of passwd file formats everywhere?
    if (@s == 7) {
	@n = getpwuid($uid_s);
	# 'nobody' et al.
	next unless @n;
	my ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
	# Protect against one-to-many and many-to-one mappings.
	if ($name_s ne $name) {
	    @n = getpwnam($name_s);
	    ($name,$passwd,$uid,$gid,$quota,$comment,$gcos,$home,$shell) = @n;
	    next if $name_s ne $name;
	}
	$suspect{$name_s}++
	    if $name    ne $name_s    or
# Shadow passwords confuse this.
# Think about non-crypt(3) encryptions, too, before you do anything rash.
#              $passwd  ne $passwd_s  or
               $uid     ne $uid_s     or
               $gid     ne $gid_s     or
               $gcos    ne $gcos_s    or
               $home    ne $home_s    or
               $shell   ne $shell_s;
    }
    $n++;
}

# Drop the multiply defined users.

foreach (sort keys %seen) {
    my $times = @{ $seen{$_} };
    if ($times > 1) {
	# Multiply defined users are rarely intentional.
	local $" = ", ";
	warn "# User '$_' defined multiple times in $where, lines: @{$seen{$_}}.\n";
	delete $suspect{$_};
    }
}

print "not " if keys %suspect;
print "ok ", $tst++, "\n";

close(PW);
