#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = "../lib" if -d "../lib";
    eval { require Config; import Config; };

    my $PW = "/etc/passwd";

    if (($^O eq 'next' and not open(PW, "nidump passwd .|"))
        or (defined $Config{'i_pwd'} and $Config{'i_pwd'} ne 'define')
	or not -f $PW or not open(PW, $PW)
	) {
	print "1..0\n";
	exit 0;
    }
}

print "1..1\n";

# Go through at most this many users.
my $max = 25; #

my $n = 0;
my $not;
my $tst = 1;

$not = 0;
while (<PW>) {
    last if $n == $max;
    chomp;
    @s = split /:/;
    if (@s == 7) {
	my ($name_s, $passwd_s, $uid_s, $gid_s, $gcos_s, $home_s, $shell_s) = @s;
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
	$not = 1, last
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

print "not " if $not;
print "ok ", $tst++, "\n";

close(PW);
