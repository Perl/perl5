#!./perl

# test added 29th April 1998 by Paul Johnson (pjcj@transeda.com)

BEGIN {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib';
}

use strict;
use IO::File;
use Test;

BEGIN {
    plan tests => 9 #, todo => [10]
}

sub lineno
{
  my ($f) = @_;
  my $l;
  $l .= "$. ";
  $l .= $f->input_line_number;
  $l .= " $.";
  $l;
}

sub OK
{
  my $s = select STDOUT;                     # work around a bug in Test.pm 1.04
  &ok;
  select $s;
}

my $t;

open (Q, __FILE__) or die $!;
my $w = IO::File->new(__FILE__) or die $!;

<Q> for (1 .. 10);
OK(lineno($w), "10 0 10");

$w->getline for (1 .. 5);
OK(lineno($w), "5 5 5");

<Q>;
OK(lineno($w), "11 5 11");

$w->getline;
OK(lineno($w), "6 6 6");

$t = tell Q;         # tell Q; provokes a warning - the world is full of bugs...
OK(lineno($w), "11 6 11");

<Q>;
OK(lineno($w), "12 6 12");

select Q;
OK(lineno($w), "12 6 12");

<Q> for (1 .. 10);
OK(lineno($w), "22 6 22");

$w->getline for (1 .. 5);
OK(lineno($w), "11 11 11");
__END__
# This test doesn't work.  It probably won't until local $. does.
$t = tell Q;
OK(lineno($w), "22 11 22", 'waiting for local $.');
