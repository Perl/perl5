#!./perl

BEGIN {
    unless(grep /blib/, @INC) {
	chdir 't' if -d 't';
	@INC = '../lib' if -d '../lib';
    }
}

use Errno;

print "1..5\n";

print "not " unless @Errno::EXPORT_OK;
print "ok 1\n";
die unless @Errno::EXPORT_OK;

$err = $Errno::EXPORT_OK[0];
$num = &{"Errno::$err"};

print "not " unless &{"Errno::$err"} == $num;
print "ok 2\n";

$! = $num;
print "not " unless $!{$err};
print "ok 3\n";

$! = 0;
print "not " if $!{$err};
print "ok 4\n";

$s1 = join(",",sort keys(%!));
$s2 = join(",",sort @Errno::EXPORT_OK);

print "not " unless $s1 eq $s2;
print "ok 5\n";
