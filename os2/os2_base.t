#!/usr/bin/perl -w
BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use Test::More tests => 24;
use strict;
use Config;

my $cwd = Cwd::sys_cwd();
ok 1;
ok -d $cwd;

my $lpb = Cwd::extLibpath;
ok 1;
$lpb .= ';' unless $lpb and $lpb =~ /;$/;

my $lpe = Cwd::extLibpath(1);
ok 1;
$lpe .= ';' unless $lpe and $lpe =~ /;$/;

ok Cwd::extLibpath_set("$lpb$cwd");

$lpb = Cwd::extLibpath;
ok 1;
$lpb =~ s#\\#/#g;
(my $s_cwd = $cwd) =~ s#\\#/#g;

like($lpb, qr/\Q$s_cwd/);

ok Cwd::extLibpath_set("$lpe$cwd", 1);

$lpe = Cwd::extLibpath(1);
ok 1;
$lpe =~ s#\\#/#g;

like($lpe, qr/\Q$s_cwd/);

is(uc OS2::DLLname(1), uc $Config{dll_name});
like(OS2::DLLname, qr#\Q/$Config{dll_name}\E\.dll$#i );
(my $root_cwd = $s_cwd) =~ s,/t$,,;
like(OS2::DLLname, qr#^\Q$root_cwd\E(/t)?\Q/$Config{dll_name}\E\.dll#i );
is(OS2::DLLname, OS2::DLLname(2));
like(OS2::DLLname(0), qr#^(\d+)$# );


is(OS2::DLLname($_), OS2::DLLname($_, \&Cwd::extLibpath) ) for 0..2;
ok(not defined eval { OS2::DLLname $_, \&Cwd::cwd; 1 } ) for 0..2;
ok(not defined eval { OS2::DLLname $_, \&xxx; 1 } ) for 0..2;
print "1.." . lasttest() . "\n";

$cwd = Cwd::sys_cwd();
print "ok 1\n";
print "not " unless -d $cwd;
print "ok 2\n";

$lpb = Cwd::extLibpath;
print "ok 3\n";
$lpb .= ';' unless $lpb and $lpb =~ /;$/;

$lpe = Cwd::extLibpath(1);
print "ok 4\n";
$lpe .= ';' unless $lpe and $lpe =~ /;$/;

Cwd::extLibpath_set("$lpb$cwd") or print "not ";
print "ok 5\n";

$lpb = Cwd::extLibpath;
print "ok 6\n";
$lpb =~ s#\\#/#g;
($s_cwd = $cwd) =~ s#\\#/#g;

print "not " unless $lpb =~ /\Q$s_cwd/;
print "ok 7\n";

Cwd::extLibpath_set("$lpe$cwd", 1) or print "not ";
print "ok 8\n";

$lpe = Cwd::extLibpath(1);
print "ok 9\n";
$lpe =~ s#\\#/#g;

print "not " unless $lpe =~ /\Q$s_cwd/;
print "ok 10\n";

unshift @INC, 'lib';
require OS2::Process;
my @l = OS2::Process::process_entry();
print "not " unless @l == 11;
print "ok 11\n";

# 1: FS 2: Window-VIO 
print "not " unless $l[9] == 1 or $l[9] == 2;
print "ok 12\n";

print "# $_\n" for @l;

sub lasttest {12}
