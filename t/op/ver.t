#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, "../lib";
}

print "1..6\n";

my $test = 1;

use v5.5.640;
require v5.5.640;
print "ok $test\n";  ++$test;

print "not " unless v1.20.300.4000 eq "\x{1}\x{14}\x{12c}\x{fa0}";
print "ok $test\n";  ++$test;

print "not " unless v1.20.300.4000 > 1.0203039 and v1.20.300.4000 < 1.0203041;
print "ok $test\n";  ++$test;

print "not " unless sprintf("%v", "Perl") eq '80.101.114.108';
print "ok $test\n";  ++$test;

print "not " unless sprintf("%v", v1.22.333.4444) eq '1.22.333.4444';
print "ok $test\n";  ++$test;

{
    use byte;
    print "not " unless
        sprintf("%v", v1.22.333.4444) eq '1.22.197.141.225.133.156';
    print "ok $test\n";  ++$test;
}
