#!/usr/bin/perl

use lib '..';
use Memoize;

my $n = 0;


if (-e '.fast') {
  print "1..0\n";
  exit 0;
}

print "1..11\n";

++$n; print "ok $n\n";

my $READFILE_CALLS = 0;
my $FILE = './TESTFILE';

sub writefile {
  my $FILE = shift;
  open F, "> $FILE" or die "Couldn't write temporary file $FILE: $!";
  print F scalar(localtime), "\n";
  close F;
}

sub readfile {
  $READFILE_CALLS++;
  my $FILE = shift;
  open F, "< $FILE" or die "Couldn't write temporary file $FILE: $!";
  my $data = <F>;
  close F;
  $data;
}

memoize 'readfile',
    SCALAR_CACHE => ['TIE', 'Memoize::ExpireFile', ],
    LIST_CACHE => 'FAULT'
    ;

++$n; print "ok $n\n";

writefile($FILE);
++$n; print "ok $n\n";
sleep 1;

my $t1 = readfile($FILE);
++$n; print "ok $n\n";
++$n; print ((($READFILE_CALLS == 1) ? '' : 'not '), "ok $n\n");

my $t2 = readfile($FILE);
++$n; print "ok $n\n";
++$n; print ((($READFILE_CALLS == 1) ? '' : 'not '), "ok $n\n");
++$n; print ((($t1 eq $t2) ? '' : 'not '), "ok $n\n");

sleep 2;
writefile($FILE);
my $t3 = readfile($FILE);
++$n; print "ok $n\n";
++$n; print ((($READFILE_CALLS == 2) ? '' : 'not '), "ok $n\n");
++$n; print ((($t1 ne $t3) ? '' : 'not '), "ok $n\n");

END { 1 while unlink 'TESTFILE' }
