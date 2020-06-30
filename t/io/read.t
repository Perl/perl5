#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
    eval 'use Errno';
    die $@ if $@ and !is_miniperl();
}

use strict;

plan tests => 4;

my $tmpfile = tempfile();

open(A,"+>$tmpfile");
print A "_";
my $rv = seek(A,0,0);
ok($rv, "seek() succeeded");

my $b = "abcd"; 
$b = "";

my $length = 1;
$rv = read(A,$b,$length,4);
is($rv, $length, "Read $length character into scalar, as expected");

close(A);

is($b,"\000\000\000\000_", "scalar modified as expected"); # otherwise probably "\000bcd_"

SKIP: {
    skip "no EBADF", 1 if (!exists &Errno::EBADF);

    $! = 0;
    no warnings 'unopened';
    no warnings 'once';
    read(B,$b,1);
    ok($! == &Errno::EBADF, "Errno::EBADF works");
}
