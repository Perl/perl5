#!perl

use Test::More tests => 4;
use XS::APItest;

av_pushnull \@_;
is $#_, 0, '$#_ after av_push(@_, NULL)';
ok !exists $_[0], '!exists $_[0] after av_push(@_,NULL)';

use Tie::Array;
tie @tied, 'Tie::StdArray';
av_pushnull \@tied;
is $#tied, 0, '$#tied after av_push(@tied, NULL)';
is $tied[0], undef, '$tied[0] is undef after av_push(@tied,NULL)';
