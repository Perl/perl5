# tr.t

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, "../lib";
}

print "1..8\n";

$_ = "abcdefghijklmnopqrstuvwxyz";

tr/a-z/A-Z/;

print "not " unless $_ eq "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
print "ok 1\n";

tr/A-Z/a-z/;

print "not " unless $_ eq "abcdefghijklmnopqrstuvwxyz";
print "ok 2\n";

tr/b-y/B-Y/;

print "not " unless $_ eq "aBCDEFGHIJKLMNOPQRSTUVWXYz";
print "ok 3\n";

# In EBCDIC 'I' is \xc9 and 'J' is \0xd1, 'i' is \x89 and 'j' is \x91.
# Yes, discontinuities.  Regardless, the \xca in the below should stay
# untouched (and not became \x8a).
{
    no utf8;
    $_ = "I\xcaJ";

    tr/I-J/i-j/;

    print "not " unless $_ eq "i\xcaj";
    print "ok 4\n";
}
#

# make sure that tr cancels IOK and NOK
($x = 12) =~ tr/1/3/;
(my $y = 12) =~ tr/1/3/;
($f = 1.5) =~ tr/1/3/;
(my $g = 1.5) =~ tr/1/3/;
print "not " unless $x + $y + $f + $g == 71;
print "ok 5\n";

# make sure tr is harmless if not updating  -  see [ID 20000511.005]
$_ = 'fred';
/([a-z]{2})/;
$1 =~ tr/A-Z//;
s/^(\s*)f/$1F/;
print "not " if $_ ne 'Fred';
print "ok 6\n";

# check tr handles UTF8 correctly
($x = 256.65.258) =~ tr/a/b/;
print "not " if $x ne 256.65.258 or length $x != 3;
print "ok 7\n";
$x =~ tr/A/B/;
print "not " if $x ne 256.66.258 or length $x != 3;
print "ok 8\n";
