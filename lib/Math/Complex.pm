#
#  Perl5 Package for complex numbers
#
#  1994 by David Nadler
#  Coding know-how provided by Tom Christiansen, Tim Bunce, and Larry Wall
#	sqrt() added by Tom Christiansen; beware should have two roots, 
#			but only returns one.  (use wantarray?)
#  
#
# The functions "Re", "Im", and "arg" are provided.
# "~" is used as the conjugation operator and "abs" is overloaded.
#
# Transcendental functions overloaded: so far only sin, cos, and exp.
#  

package Math::Complex;

require Exporter;

@ISA = ('Exporter');

# just to make use happy

%OVERLOAD= (
    '+'   => sub  { my($x1,$y1,$x2,$y2) = (@{$_[0]},@{$_[1]});
                      bless [ $x1+$x2, $y1+$y2];
             },

    '-'   => sub  { my($x1,$y1,$x2,$y2) = (@{$_[0]},@{$_[1]});
                      bless [ $x1-$x2, $y1-$y2];
             },

    '*'   => sub  { my($x1,$y1,$x2,$y2) = (@{$_[0]},@{$_[1]});
                    bless [ $x1*$x2-$y1*$y2,$x1*$y2+$x2*$y1];
             },

    '/'   => sub  { my($x1,$y1,$x2,$y2) = (@{$_[0]},@{$_[1]});
                    my $q = $x2*$x2+$y2*$y2;
                    bless [($x1*$x2+$y1*$y2)/$q, ($y1*$x2-$y2*$x1)/$q];
             },

    'neg' => sub  { my($x,$y) = @{$_[0]}; bless [ -$x, -$y];
             },

    '~'   => sub  { my($x,$y) = @{$_[0]}; bless [ $x, -$y];
             },

    'abs'   => sub  { my($x,$y) = @{$_[0]}; sqrt $x*$x+$y*$y;
             },

    'cos' => sub { my($x,$y) = @{$_[0]};
                   my ($ab,$c,$s) = (exp $y, cos $x, sin $x);
                   my $abr = 1/(2*$ab); $ab /= 2;
                   bless [ ($abr+$ab)*$c, ($abr-$ab)*$s];
             },

    'sin' => sub { my($x,$y) = @{$_[0]};
                   my ($ab,$c,$s) = (exp $y, cos $x, sin $x);
                   my $abr = 1/(2*$ab); $ab /= 2;
                   bless [ (-$abr-$ab)*$s, ($abr-$ab)*$c];
             },

    'exp' => sub { my($x,$y) = @{$_[0]};
                   my ($ab,$c,$s) = (exp $x, cos $y, sin $y);
                   bless [ $ab*$c, $ab*$s ];
              },

    'sqrt' => sub { 
	my($zr,$zi) = @{$_[0]};
	my ($x, $y, $r, $w);
	my $c = new Math::Complex (0,0);
        if (($zr == 0) && ($zi == 0)) { 
	    # nothing, $c already set
	}
        else {
	  $x = abs($zr);
	  $y = abs($zi);
	  if ($x >= $y) { 
	      $r = $y/$x; 
	      $w = sqrt($x) * sqrt(0.5*(1.0+sqrt(1.0+$r*$r))); 
	  }
	  else { 
	      $r = $x/$y; 
	      $w = sqrt($y) * sqrt($y) * sqrt(0.5*($r+sqrt(1.0+$r*$r))); 
	  }
	  if ( $zr >= 0) { 
	      @$c = ($w, $zi/(2 * $w) ); 
	  }
	  else { 
	      $c->[1] = ($zi >= 0) ? $w : -$w;
	      $c->[0] = $zi/(2.0* $c->[1]); 
	  }
        } 
        return $c;
      },

    qw("" stringify)
);

sub new {
    shift;
    my @C = @_;
    bless \@C;
}

sub Re {
    my($x,$y) = @{$_[0]};
    $x;
}

sub Im {
    my($x,$y) = @{$_[0]};
    $y;
}

sub arg {
    my($x,$y) = @{$_[0]};
    atan2($y,$x);
}

sub stringify {
    my($x,$y) = @{$_[0]};
    my($re,$im);

    $re = $x if ($x);
    if ($y == 1) {$im = 'i';}  
    elsif ($y == -1){$im = '-i';} 
    elsif ($y) {$im = "${y}i"; }

    local $_ = $re.'+'.$im;
    s/\+-/-/;
    s/^\+//;
    s/[\+-]$//;
    $_ = 0 if ($_ eq '');
    return $_;
}
