#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

BEGIN {
    our $hasgr;
    eval { my @n = getgrgid 0 };
    $hasgr = 1 unless $@ && $@ =~ /unimplemented/;
    unless ($hasgr) { print "1..0 # Skip: no getgrgid\n"; exit 0 }
    use Config;
    $hasgr = 0 unless $Config{'i_grp'} eq 'define';
    unless ($hasgr) { print "1..0 # Skip: no grp.h\n"; exit 0 }
}

BEGIN {
    our @grent = getgrgid 0; # This is the function getgrgid.
    unless (@grent) { print "1..0 # Skip: no gid 0\n"; exit 0 }
}

print "1..5\n";

use User::grent;

print "ok 1\n";

my $grent = getgrgid 0; # This is the OO getgrgid.

print "not " unless $grent->gid    == 0;
print "ok 2\n";

print "not " unless $grent->name   == $grent[0];
print "ok 3\n";

print "not " unless $grent->passwd eq $grent[1];
print "ok 4\n";

print "not " unless $grent->gid    == $grent[2];
print "ok 5\n";

# Testing pretty much anything else is unportable.

