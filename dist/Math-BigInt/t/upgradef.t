#!/usr/bin/perl -w

use Test;
use strict;

BEGIN
  {
  plan tests => 0
   + 6;			# our own tests
  }

###############################################################################
package Math::BigFloat::Test;

use Math::BigFloat;
require Exporter;
use vars qw/@ISA/;
@ISA = qw/Exporter Math::BigFloat/;

use overload;

sub isa
  {
  my ($self,$class) = @_;
  return if $class =~ /^Math::Big(Int|Float)/;	# we aren't one of these
  UNIVERSAL::isa($self,$class);
  }

sub bmul
  {
  return __PACKAGE__->new(123);
  }

sub badd
  {
  return __PACKAGE__->new(321);
  }

###############################################################################
package main;

# use Math::BigInt upgrade => 'Math::BigFloat';
use Math::BigFloat upgrade => 'Math::BigFloat::Test';

use vars qw ($scale $class $try $x $y $z $f @args $ans $ans1 $ans1_str $setup
             $ECL $CL);
$class = "Math::BigFloat";
$CL = "Math::BigInt::Calc";
$ECL = "Math::BigFloat::Test";

ok (Math::BigFloat->upgrade(),$ECL);
ok (Math::BigFloat->downgrade()||'','');

$x = $class->new(123); $y = $ECL->new(123); $z = $x->bmul($y);
ok (ref($z),$ECL); ok ($z,123);

$x = $class->new(123); $y = $ECL->new(123); $z = $x->badd($y);
ok (ref($z),$ECL); ok ($z,321);



# not yet:
# require 'upgrade.inc';	# all tests here for sharing
