#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN {
    our $haspw;
    eval { my @n = getpwuid 0 };
    $haspw = 1 unless $@ && $@ =~ /unimplemented/;
    unless ($haspw) { print "1..0 # Skip: no getpwuid\n"; exit 0 }
    use Config;
    $haspw = 0 unless $Config{'i_pwd'} eq 'define';
    unless ($haspw) { print "1..0 # Skip: no pwd.h\n"; exit 0 }
}

BEGIN {
    our @pwent = getpwuid 0; # This is the function getpwuid.
    unless (@pwent) { print "1..0 # Skip: no uid 0\n"; exit 0 }
}

print "1..9\n";

use User::pwent;

print "ok 1\n";

my $pwent = getpwuid 0; # This is the OO getpwuid.

print "not " unless $pwent->uid    == 0 ||
                    ($^O eq 'cygwin'  && $pwent->uid == 500); # go figure
print "ok 2\n";

print "not " unless $pwent->name   == $pwent[0];
print "ok 3\n";

print "not " unless $pwent->passwd eq $pwent[1];
print "ok 4\n";

print "not " unless $pwent->uid    == $pwent[2];
print "ok 5\n";

print "not " unless $pwent->gid    == $pwent[3];
print "ok 6\n";

# The quota and comment fields are unportable.

print "not " unless $pwent->gecos  eq $pwent[6];
print "ok 7\n";

print "not " unless $pwent->dir    eq $pwent[7];
print "ok 8\n";

print "not " unless $pwent->shell  eq $pwent[8];
print "ok 9\n";

# The expire field is unportable.

# Testing pretty much anything else is unportable:
# there maybe more than one username with uid 0;
# uid 0's home directory may be "/" or "/root' or something else,
# and so on.

