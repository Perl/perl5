#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '.';
    push @INC, '../lib';
}

print "1..10\n";

#
# This file tries to test builtin override using CORE::GLOBAL
#
my $dirsep = "/";

BEGIN { package Foo; *main::getlogin = sub { "kilroy"; } }

print "not " unless getlogin eq "kilroy";
print "ok 1\n";

my $t = 42;
BEGIN { *CORE::GLOBAL::time = sub () { $t; } }

print "not " unless 45 == time + 3;
print "ok 2\n";

#
# require has special behaviour
#
my $r;
BEGIN { *CORE::GLOBAL::require = sub { $r = shift; 1; } }

require Foo;
print "not " unless $r eq "Foo.pm";
print "ok 3\n";

require Foo::Bar;
print "not " unless $r eq join($dirsep, "Foo", "Bar.pm");
print "ok 4\n";

require 'Foo';
print "not " unless $r eq "Foo";
print "ok 5\n";

require 5.6;
print "not " unless $r eq "5.6";
print "ok 6\n";

require v5.6;
print "not " unless abs($r - 5.006) < 0.001 && $r eq "\x05\x06";
print "ok 7\n";

eval "use Foo";
print "not " unless $r eq "Foo.pm";
print "ok 8\n";

eval "use Foo::Bar";
print "not " unless $r eq join($dirsep, "Foo", "Bar.pm");
print "ok 9\n";

eval "use 5.6";
print "not " unless $r eq "5.6";
print "ok 10\n";
