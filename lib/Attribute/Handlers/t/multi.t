END {print "not ok 1\n" unless $loaded;}
use v5.6.0;
use Attribute::Handlers;
$loaded = 1;

CHECK { $main::phase++ }

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

sub ok { $::count++; push @::results, [$_[1], $_[0]?"":"not "]; }

END { print "1..$::count\n";
      print map "$_->[1]ok $_->[0]\n",
		sort {$a->[0]<=>$b->[0]}
			grep $_->[0], @::results }

package Test;
use warnings;
no warnings 'redefine';

sub UNIVERSAL::Lastly :ATTR(INIT) { ::ok $_[4][0] && $main::phase, $_[4][1] }

sub UNIVERSAL::Okay :ATTR(BEGIN) { ::ok  $_[4][0] && !$main::phase, $_[4][1] }

sub Dokay :ATTR(SCALAR) { ::ok @{$_[4]} }
sub Dokay :ATTR(HASH)   { ::ok @{$_[4]} }
sub Dokay :ATTR(ARRAY)  { ::ok @{$_[4]} }
sub Dokay :ATTR(CODE)   { ::ok @{$_[4]} }

sub Vokay :ATTR(VAR)    { ::ok @{$_[4]} }

sub Aokay :ATTR(ANY)    { ::ok @{$_[4]} }

package main;
use warnings;

my $x1 :Lastly(1,41);
my @x1 :Lastly(1=>42);
my %x1 :Lastly(1,43);
sub x1 :Lastly(1,44) {}

my Test $x2 :Dokay(1,5);

package Test;
my $x3 :Dokay(1,6);
my Test $x4 :Dokay(1,7);
sub x3 :Dokay(1,8) {}

my $y1 :Okay(1,9);
my @y1 :Okay(1,10);
my %y1 :Okay(1,11);
sub y1 :Okay(1,12) {}

my $y2 :Vokay(1,13);
my @y2 :Vokay(1,14);
my %y2 :Vokay(1,15);
# BEGIN {eval 'sub y2 :Vokay(0,16) {}; 1' or
::ok(1,16);
# }

my $z :Aokay(1,17);
my @z :Aokay(1,18);
my %z :Aokay(1,19);
sub z :Aokay(1,20) {};

package DerTest;
use base 'Test';
use warnings;

my $x5 :Dokay(1,21);
my Test $x6 :Dokay(1,22);
sub x5 :Dokay(1,23);

my $y3 :Okay(1,24);
my @y3 :Okay(1,25);
my %y3 :Okay(1,26);
sub y3 :Okay(1,27) {}

package Unrelated;

my $x11 :Okay(1,1);
my @x11 :Okay(1=>2);
my %x11 :Okay(1,3);
sub x11 :Okay(1,4) {}

BEGIN { eval 'my $x7 :Dokay(0,28)' or ::ok(1,28); }
my Test $x8 :Dokay(1,29);
eval 'sub x7 :Dokay(0,30) {}' or ::ok(1,30);


package Tie::Loud;

sub TIESCALAR { ::ok(1,31); bless {}, $_[0] }
sub FETCH { ::ok(1,32); return 1 }
sub STORE { ::ok(1,33); return 1 }

package Tie::Noisy;

sub TIEARRAY { ::ok(1,$_[1]); bless {}, $_[0] }
sub FETCH { ::ok(1,35); return 1 }
sub STORE { ::ok(1,36); return 1 }
sub FETCHSIZE { 100 }

package Tie::Row::dy;

sub TIEHASH { ::ok(1,$_[1]); bless {}, $_[0] }
sub FETCH { ::ok(1,38); return 1 }
sub STORE { ::ok(1,39); return 1 }

package main;

eval 'sub x7 :ATTR(SCALAR) :ATTR(CODE) {}' and ::ok(0,40) or ::ok(1,40);

use Attribute::Handlers autotie => {      Other::Loud => Tie::Loud,
				                Noisy => Tie::Noisy,
				     UNIVERSAL::Rowdy => Tie::Row::dy,
                                   };

my Other $loud : Loud;
$loud++;

my @noisy : Noisy(34);
$noisy[0]++;

my %rowdy : Rowdy(37);
$rowdy{key}++;

