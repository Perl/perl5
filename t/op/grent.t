#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = "../lib" if -d "../lib";
    eval { require Config; import Config; };

    my $GR = "/etc/group";

    if (($^O eq 'next' and not open(GR, "nidump group .|"))
	or (defined $Config{'i_grp'} and $Config{'i_grp'} ne 'define')
	or not -f $GR or not open(GR, $GR)
	) {
	print "1..0\n";
	exit 0;
    }
}

print "1..1\n";

# Go through at most this many groups.
my $max = 25; #

my $n = 0;
my $not;
my $tst = 1;

$not = 0;
while (<GR>) {
    last if $n == $max;
    chomp;
    @s = split /:/;
    if (@s == 4) {
	my ($name_s,$passwd_s,$gid_s,$members_s) = @s;
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
	$not = 1, last
	    if $name    ne $name_s    or
# Shadow passwords confuse this.
# Not that group passwords are used much but still.
#              $passwd  ne $passwd_s  or
               $gid     ne $gid_s     or
               $members ne $members_s;
    }
    $n++;
}

print "not " if $not;
print "ok ", $tst++, "\n";

close(GR);
