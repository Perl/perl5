#!./perl

BEGIN {
    chdir 't' if -d 't';
    require './test.pl';
    set_up_inc('../lib');
}
use warnings;
use utf8;
use open qw( :utf8 :std );

plan(tests => 1);

=pod 

=encoding UTF-8

From the parrot test t/pmc/object-meths.t

 ଅ   ᛒ ଅ   ऍ
  \ /   \ /
   ƈ     Ḋ
    \   /
     \ /
      Ḟ

=cut

{
    package Ƭ::ŁiƁ::ଅ; use mro 'dfs';
    package Ƭ::ŁiƁ::ᛒ; use mro 'dfs';
    package Ƭ::ŁiƁ::ऍ; use mro 'dfs';
    package Ƭ::ŁiƁ::ƈ; use mro 'dfs'; use base ('Ƭ::ŁiƁ::ଅ', 'Ƭ::ŁiƁ::ᛒ');
    package Ƭ::ŁiƁ::Ḋ; use mro 'dfs'; use base ('Ƭ::ŁiƁ::ଅ', 'Ƭ::ŁiƁ::ऍ');
    package Ƭ::ŁiƁ::Ḟ; use mro 'dfs'; use base ('Ƭ::ŁiƁ::ƈ', 'Ƭ::ŁiƁ::Ḋ');
}

ok(eq_array(
    mro::get_linear_isa('Ƭ::ŁiƁ::Ḟ'),
    [ qw(Ƭ::ŁiƁ::Ḟ Ƭ::ŁiƁ::ƈ Ƭ::ŁiƁ::ଅ Ƭ::ŁiƁ::ᛒ Ƭ::ŁiƁ::Ḋ Ƭ::ŁiƁ::ऍ) ]
), '... got the right MRO for Ƭ::ŁiƁ::Ḟ');  

