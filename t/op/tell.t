#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

# NOTE: we cannot use seek() here because using that *portably* would mean
# using Fcntl and the principle is not to use any extensions in the t/op/*

print "1..6\n";

{
no warnings 'io';
print "not " unless tell(TEST) == -1;
print "ok 1\n";
}

open(TEST, "TEST")	|| die "$0: failed to open 'TEST' for reading: $!\n";

print "not " unless tell(TEST) == 0;
print "ok 2\n";

my ($s, $read);

$read = read(TEST, $s, 2);

$read == 2		|| warn "$0: read() returned $read, expected 2\n";
$s eq '#!'		|| warn "$0: read() read '$s', expected '#!'\n";

print "not " unless tell(TEST)  == 2;
print "ok 3\n";

print "not " unless tell()      == 2;
print "ok 4\n";

my $TEST = 'TEST';

print "not " unless tell($TEST) == 2;
print "ok 5\n";

close(TEST)		|| warn "$0: close() failed: $!\n";

{
no warnings 'io';
print "not " unless tell(TEST) == -1;
print "ok 6\n";
}

# ftell(STDIN) (or any std streams) is undefined, it can return -1 or
# something else.  ftell() on pipes, fifos, and sockets is defined to
# return -1.

