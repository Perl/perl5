#!./perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '.'; 
    push @INC, '../lib';
}    

{
 package Basic;
 use Tie::Array;
 our @ISA = qw(Tie::Array);

 sub TIEARRAY  { return bless [], shift }
 sub FETCH     { $_[0]->[$_[1]] }
 sub STORE     { $_[0]->[$_[1]] = $_[2] }
 sub FETCHSIZE { scalar(@{$_[0]}) }
 sub STORESIZE { $#{$_[0]} = $_[1]-1 }
}

tie my @x, 'Basic';
tie my @get, 'Basic';
tie my @got, 'Basic';
tie my @tests, 'Basic';
require "op/push.t"
