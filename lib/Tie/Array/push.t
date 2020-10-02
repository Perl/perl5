#!./perl

use strict;
use warnings;

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

tie our @x, 'Basic';
tie our @get, 'Basic';
tie our @got, 'Basic';
tie our @tests, 'Basic';
require "op/push.t"
