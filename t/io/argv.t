#!./perl

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib';
}

print "1..14\n";

use File::Spec;

my $devnull = File::Spec->devnull;

open(try, '>Io.argv.tmp') || (die "Can't open temp file: $!");
print try "a line\n";
close try;

if ($^O eq 'MSWin32') {
  $x = `.\\perl -e "while (<>) {print \$.,\$_;}" Io.argv.tmp Io.argv.tmp`;
}
else {
  $x = `./perl -e 'while (<>) {print \$.,\$_;}' Io.argv.tmp Io.argv.tmp`;
}
if ($x eq "1a line\n2a line\n") {print "ok 1\n";} else {print "not ok 1\n";}

if ($^O eq 'MSWin32') {
  $x = `.\\perl -le "print 'foo'" | .\\perl -e "while (<>) {print \$_;}" Io.argv.tmp -`;
}
else {
  $x = `echo foo|./perl -e 'while (<>) {print $_;}' Io.argv.tmp -`;
}
if ($x eq "a line\nfoo\n") {print "ok 2\n";} else {print "not ok 2\n";}

if ($^O eq 'MSWin32') {
  $x = `.\\perl -le "print 'foo'" |.\\perl -e "while (<>) {print \$_;}"`;
}
else {
  $x = `echo foo|./perl -e 'while (<>) {print $_;}'`;
}
if ($x eq "foo\n") {print "ok 3\n";} else {print "not ok 3 :$x:\n";}

@ARGV = ('Io.argv.tmp', 'Io.argv.tmp', $devnull, 'Io.argv.tmp');
while (<>) {
    $y .= $. . $_;
    if (eof()) {
	if ($. == 3) {print "ok 4\n";} else {print "not ok 4\n";}
    }
}

if ($y eq "1a line\n2a line\n3a line\n")
    {print "ok 5\n";}
else
    {print "not ok 5\n";}

open(try, '>Io.argv.tmp') or die "Can't open temp file: $!";
close try;
@ARGV = 'Io.argv.tmp';
$^I = '.bak';
$/ = undef;
while (<>) {
    s/^/ok 6\n/;
    print;
}
open(try, '<Io.argv.tmp') or die "Can't open temp file: $!";
print while <try>;
close try;
undef $^I;

eof try or print 'not ';
print "ok 7\n";

eof NEVEROPENED or print 'not ';
print "ok 8\n";

open STDIN, 'Io.argv.tmp' or die $!;
@ARGV = ();
!eof() or print 'not ';
print "ok 9\n";

<> eq "ok 6\n" or print 'not ';
print "ok 10\n";

open STDIN, $devnull or die $!;
@ARGV = ();
eof() or print 'not ';
print "ok 11\n";

@ARGV = ('Io.argv.tmp');
!eof() or print 'not ';
print "ok 12\n";

@ARGV = ($devnull, $devnull);
!eof() or print 'not ';
print "ok 13\n";

close ARGV or die $!;
eof() or print 'not ';
print "ok 14\n";

END { unlink 'Io.argv.tmp', 'Io.argv.tmp.bak' }
