#!./perl -w

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib' if -f '../lib/Carp.pm';
}

if ($^O =~ /^(MSWin32|os2|NetWare|dos)$/) {
    print "1..25\n";
}
else {
    print "1..0 # skipped: not a dosish system\n";
    exit 0;
}

use Fcntl qw(:DEFAULT :seek);
my $tmpf = "sysioc.tmp";
my $n;
my $v;
END { unlink $tmpf }

# default read/write modes should be text
{
    sysopen(my $F, $tmpf, O_CREAT|O_RDWR|O_TRUNC) or die "Can't open $tmpf: $!";
    $n = syswrite($F, "zyx\n");
    print "not " unless $n == 4;
    print "ok 1\n";
}
# must be flushed and closed here
print "not " if (-s $tmpf) != 5;  # should be "zyx\r\n"
print "ok 2\n";

{
    sysopen(my $F, $tmpf, O_RDONLY) or die "Can't open $tmpf: $!";
    $n = sysread($F, $v, 4);
    print "not " unless $n == 4;
    print "ok 3\n";
    print "not " unless $v eq "zyx\n";
    print "ok 4\n";
    $n = sysread($F, $v, 10);
    print "not " unless $n == 0; # eof
    print "ok 5\n";
    $n = sysseek($F, 0, SEEK_SET);
    print "not " unless $n == 0;
    print "ok 6\n";
    $n = sysread($F, $v, 10);
    print "not " unless $n == 4; # short read
    print "ok 7\n";
    print "not " unless $v eq "zyx\n";
    print "ok 8\n";
}

# reading in binmode should see real contents
{
    sysopen(my $F, $tmpf, O_RDONLY|O_BINARY) or die "Can't open $tmpf: $!";
    $n = sysread($F, $v, 5);
    print "not " unless $n == 5;
    print "ok 9\n";
    print "not " unless $v eq "zyx\r\n";
    print "ok 10\n";
    $n = sysread($F, $v, 10);
    print "not " unless $n == 0; # eof
    print "ok 11\n";
    $n = sysseek($F, 0, SEEK_SET);
    print "not " unless $n == 0;
    print "ok 12\n";
    $n = sysread($F, $v, 10);
    print "not " unless $n == 5; # short read
    print "ok 13\n";
    print "not " unless $v eq "zyx\r\n";
    print "ok 14\n";
}

# ^Z handling
{
    sysopen(my $F, $tmpf, O_CREAT|O_RDWR|O_TRUNC|O_BINARY) or die "Can't open $tmpf: $!";
    $n = syswrite($F, "zyx\r\n\cZpqr");
    print "not " unless $n == 9;
    print "ok 15\n";
}
# must be flushed and closed here
print "not " if (-s $tmpf) != 9;  # should be "zyx\r\n\cZpqr"
print "ok 16\n";

{
    sysopen(my $F, $tmpf, O_RDONLY) or die "Can't open $tmpf: $!";
    $n = sysread($F, $v, 4);
    print "not " unless $n == 4;
    print "ok 17\n";
    print "not " unless $v eq "zyx\n";
    print "ok 18\n";
    $n = sysread($F, $v, 10); # eof
    print "not " unless $n == 0;
    print "ok 19\n";
    $n = sysseek($F, 0, SEEK_SET);
    print "not " unless $n == 0;
    print "ok 20\n";
    $n = sysread($F, $v, 10);
    print "not " unless $n == 4; # short read
    print "ok 21\n";
    print "not " unless $v eq "zyx\n";
    print "ok 22\n";
    $n = sysread($F, $v, 10); # eof
    print "not " unless $n == 0;
    print "ok 23\n";
}

# reading in binmode should see real contents
{
    sysopen(my $F, $tmpf, O_RDONLY|O_BINARY) or die "Can't open $tmpf: $!";
    $n = sysread($F, $v, 9);
    print "not " unless $n == 9;
    print "ok 24\n";
    print "not " unless $v eq "zyx\r\n\cZpqr";
    print "ok 25\n";
}
