#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

use strict;

plan 43;

sub context {
  local $::Level = $::Level + 1;
  my ( $cona, $name ) = @_;
  my $conb = (defined wantarray) ? ( wantarray ? 'A' : 'S' ) : 'V';
  is $conb, $cona, $name;
}

context('V');
my $a = context('S');
my @a = context('A');
scalar context('S');
$a = scalar context('S');
($a) = context('A');
($a) = scalar context('S');

{
  # [ID 20020626.011] incorrect wantarray optimisation
  sub simple { wantarray ? 1 : 2 }
  sub inline {
    my $a = wantarray ? simple() : simple();
    $a;
  }
  my @b = inline();
  my $c = inline();
  is @b, 1;
  is "@b", "2";
  is $c, 2;
}

my $q;

my $qcontext = q{
  $q = (defined wantarray) ? ( wantarray ? 'A' : 'S' ) : 'V';
};
eval $qcontext;
is $q, 'V';
$a = eval $qcontext;
is $q, 'S';
@a = eval $qcontext;
is $q, 'A';

# Test with various ops that the right context is used at the end of a sub-
# routine (run-time context).
$::t = 1;
$::f = 0;
$::u = undef;
sub or_context { $::f || context(shift, "rhs of || at sub exit") }
or_context('V');
$_ = or_context('S');
() = or_context('A');
sub and_context { $::t && context(shift, "rhs of && at sub exit") }
and_context('V');
$_ = and_context('S');
() = and_context('A');
sub dor_context { $::u // context(shift, "rhs of // at sub exit") }
dor_context('V');
$_ = dor_context('S');
() = dor_context('A');
sub cond_middle_cx { $::t ? context(shift, "mid of ?: at sub exit") : 0 }
cond_middle_cx('V');
$_ = cond_middle_cx('S');
() = cond_middle_cx('A');
sub cond_rhs_cx { $::f ? 0 : context(shift, "rhs of ?: at sub exit") }
cond_rhs_cx('V');
$_ = cond_rhs_cx('S');
() = cond_rhs_cx('A');
sub comma_context{ context(shift, "lhs of comma at sub exit"),
                   context(shift, "rhs of comma at sub exit") }
comma_context('V','V');
$_ = comma_context('V','S');
() = comma_context('A','A');
sub x_context { (context(shift, "(lhs) of x at sub exit")) x $::t }
x_context('S');
$_ = x_context('S');
() = x_context('A');
sub comma_in_x {
    (context(shift, "cx of foo in (foo,bar)xbaz at sub exit"),
     context(shift, "cx of bar in (foo,bar)xbaz at sub exit"))
      x $::t
}
comma_in_x('V','S');
$_ = comma_in_x('V','S');
() = comma_in_x('A','A');

1;
