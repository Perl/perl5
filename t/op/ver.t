#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

print "1..37\n";

my $test = 1;

sub okeq {
    my $ok = $_[0] eq $_[1];;
    print "not " unless $ok;
    print "ok ", $test++;
    print " # $_[2]" if !$ok && @_ == 3;
    print "\n";
}

sub skip { print "ok ", $test++, " # Skip: $_[0]\n" }

use v5.5.640;
require v5.5.640;
print "ok $test\n";  ++$test;

# printing characters should work
if (ord("\t") == 9) { # ASCII
    print v111;
    print v107.32;
    print "$test\n"; ++$test;

    # hash keys too
    $h{v111.107} = "ok";
    print "$h{ok} $test\n"; ++$test;
}
else { # EBCDIC
    print v150;
    print v146.64;
    print "$test\n"; ++$test;

    # hash keys too
    $h{v150.146} = "ok";
    print "$h{ok} $test\n"; ++$test;
}

# poetry optimization should also
sub v77 { "ok" }
$x = v77;
print "$x $test\n"; ++$test;

# but not when dots are involved
if (ord("\t") == 9) { # ASCII
    $x = v77.78.79;
}
else {
    $x = v212.213.214;
}
okeq($x, "MNO");

okeq(v1.20.300.4000, "\x{1}\x{14}\x{12c}\x{fa0}");

#
# now do the same without the "v"
use 5.5.640;
require 5.5.640;
print "ok $test\n";  ++$test;

# hash keys too
if (ord("\t") == 9) { # ASCII
    $h{111.107.32} = "ok";
}
else {
    $h{150.146.64} = "ok";
}
print "$h{ok } $test\n"; ++$test;

if (ord("\t") == 9) { # ASCII
    $x = 77.78.79;
}
else {
    $x = 212.213.214;
}
okeq($x, "MNO");

okeq(1.20.300.4000, "\x{1}\x{14}\x{12c}\x{fa0}");

# test sprintf("%vd"...) etc
if (ord("\t") == 9) { # ASCII
    okeq(sprintf("%vd", "Perl"), '80.101.114.108');
}
else {
    okeq(sprintf("%vd", "Perl"), '215.133.153.147');
}

okeq(sprintf("%vd", v1.22.333.4444), '1.22.333.4444');

if (ord("\t") == 9) { # ASCII
    okeq(sprintf("%vx", "Perl"), '50.65.72.6c');
}
else {
    okeq(sprintf("%vx", "Perl"), 'd7.85.99.93');
}

okeq(sprintf("%vX", 1.22.333.4444), '1.16.14D.115C');

if (ord("\t") == 9) { # ASCII
    okeq(sprintf("%#*vo", ":", "Perl"), '0120:0145:0162:0154');
}
else {
    okeq(sprintf("%#*vo", ":", "Perl"), '0327:0205:0231:0223');
}

okeq(sprintf("%*vb", "##", v1.22.333.4444),
    '1##10110##101001101##1000101011100');

okeq(sprintf("%vd", join("", map { chr }
			 unpack 'U*', pack('U*',2001,2002,2003))),
     '2001.2002.2003');

{
    use bytes;

    if (ord("\t") == 9) { # ASCII
        okeq(sprintf("%vd", "Perl"), '80.101.114.108');
    }
    else {
        okeq(sprintf("%vd", "Perl"), '215.133.153.147');
    }

    if (ord("\t") == 9) { # ASCII
	okeq(sprintf("%vd", 1.22.333.4444), '1.22.197.141.225.133.156');
    }
    else {
        okeq(sprintf("%vd", 1.22.333.4444), '1.22.142.84.187.81.112');
    }

    if (ord("\t") == 9) { # ASCII
        okeq(sprintf("%vx", "Perl"), '50.65.72.6c');
    }
    else {
        okeq(sprintf("%vx", "Perl"), 'd7.85.99.93');
    }

    if (ord("\t") == 9) { # ASCII
        okeq(sprintf("%vX", v1.22.333.4444), '1.16.C5.8D.E1.85.9C');
    }
    else {
        okeq(sprintf("%vX", v1.22.333.4444), '1.16.8E.54.BB.51.70');
    }

    if (ord("\t") == 9) { # ASCII
        okeq(sprintf("%#*vo", ":", "Perl"), '0120:0145:0162:0154');
    }
    else {
        okeq(sprintf("%#*vo", ":", "Perl"), '0327:0205:0231:0223');
    }

    if (ord("\t") == 9) { # ASCII
        okeq(sprintf("%*vb", "##", v1.22.333.4444),
	     '1##10110##11000101##10001101##11100001##10000101##10011100');
    }
    else {
        okeq(sprintf("%*vb", "##", v1.22.333.4444),
            '1##10110##10001110##1010100##10111011##1010001##1110000');
    }
}

{
    # 24..28

    # bug id 20000323.056

    print "not " unless "\x{41}" eq +v65;
    print "ok $test\n";
    $test++;

    print "not " unless "\x41" eq +v65;
    print "ok $test\n";
    $test++;

    print "not " unless "\x{c8}" eq +v200;
    print "ok $test\n";
    $test++;

    print "not " unless "\xc8" eq +v200;
    print "ok $test\n";
    $test++;

    print "not " unless "\x{221b}" eq v8731;
    print "ok $test\n";
    $test++;
}

# See if the things Camel-III says are true: 29..33

# Chapter 2 pp67/68
my $vs = v1.20.300.4000;
okeq($vs,"\x{1}\x{14}\x{12c}\x{fa0}","v-string ne \\x{}");
okeq($vs,chr(1).chr(20).chr(300).chr(4000),"v-string ne chr()");
okeq('foo',((chr(193) eq 'A') ? v134.150.150 : v102.111.111),"v-string ne ''");

# Chapter 15, pp403

# See if sane addr and gethostbyaddr() work
eval { require Socket; gethostbyaddr(v127.0.0.1, Socket::AF_INET) };
if ($@)
 {
  # No - so don't test insane fails.
  $@ =~ s/\n/\n# /g;
  skip("No Socket::AF_INET # $@");
 }
else
 {
  my $ip   = v2004.148.0.1;
  my $host;
  eval { $host = gethostbyaddr($ip,Socket::AF_INET) };
  okeq($@ =~ /Wide character/,1,"Non-bytes leak to gethostbyaddr");
 }

# Chapter 28, pp671
okeq(v5.6.0 lt v5.7.0,1,"v5.6.0 lt v5.7.0 fails");

# floating point too messy
# my $v = ord($^V)+ord(substr($^V,1,1))/1000+ord(substr($^V,2,1))/1000000;
# okeq($v,$],"\$^V and \$] do not match");

# 34..37: part of 20000323.059
print "not " unless v200 eq chr(200);
print "ok 34\n";

print "not " unless v200 eq +v200;
print "ok 35\n";

print "not " unless v200 eq eval "v200";
print "ok 36\n";

print "not " unless v200 eq eval "+v200";
print "ok 37\n";

