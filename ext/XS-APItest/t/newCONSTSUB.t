#!perl

use strict;
use warnings;
use utf8;
use open qw( :utf8 :std );
use Test::More tests => 11;

use XS::APItest;

my ($const, $glob) = XS::APItest::newCONSTSUB_type(\%::, "sanity_check", 0, 0);

ok $const;
ok *{$glob}{CODE};

($const, $glob) = XS::APItest::newCONSTSUB_type(\%::, "\x{30cb}", 0, 0);
ok $const, "newCONSTSUB generates the constant,";
ok *{$glob}{CODE}, "..and the glob,";
ok !$::{"\x{30cb}"}, "...but not the right one";

($const, $glob) = XS::APItest::newCONSTSUB_type(\%::, "\x{30cd}", 0, 1);
ok $const, "newCONSTSUB_flags generates the constant,";
ok *{$glob}{CODE}, "..and the glob,";
ok $::{"\x{30cd}"}, "...the right one!";

eval q{
 BEGIN {
  no warnings;
  my $w;
  local $SIG{__WARN__} = sub { $w .= shift };
  *foo = sub(){123};
  newCONSTSUB_type(\%::, "foo", 0, 1);
  is $w, undef, 'newCONSTSUB uses calling scope for redefinition warnings';
 }
};

{
 no strict 'refs';
 *{"foo::\x{100}"} = sub(){return 123};
 my $w;
 local $SIG{__WARN__} = sub { $w .= shift };
 newCONSTSUB_type(\%foo::, "\x{100}", 0, 1);
 like $w, qr/Subroutine \x{100} redefined at /,
   'newCONSTSUB redefinition warning + utf8';
 undef $w;
 newCONSTSUB_type(\%foo::, "\x{100}", 0, 1);
 like $w, qr/Constant subroutine \x{100} redefined at /,
   'newCONSTSUB constant redefinition warning + utf8';
}
