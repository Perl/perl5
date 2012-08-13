#!perl

use strict;
use utf8;
use open qw( :utf8 :std );
use Test::More tests => 14;

use XS::APItest;

# This test must happen outside of any warnings scope
{
 local $^W;
 my $w;
 local $SIG{__WARN__} = sub { $w .= shift };
 sub frimple() { 78 }
 newCONSTSUB_flags(\%::, "frimple", 0, undef);
 like $w, qr/Constant subroutine frimple redefined at /,
   'newCONSTSUB constant redefinition warning is unaffected by $^W=0';
 undef $w;
 newCONSTSUB_flags(\%::, "frimple", 0, undef);
 is $w, undef, '...unless the const SVs are the same';
 eval 'sub frimple() { 78 }';
 undef $w;
 newCONSTSUB_flags(\%::, "frimple", 0, "78");
 is $w, undef, '...or the const SVs have the same value';
}

use warnings;

my ($const, $glob) =
 XS::APItest::newCONSTSUB(\%::, "sanity_check", 0, undef);

ok $const;
ok *{$glob}{CODE};

($const, $glob) =
  XS::APItest::newCONSTSUB(\%::, "\x{30cb}", 0, undef);
ok $const, "newCONSTSUB generates the constant,";
ok *{$glob}{CODE}, "..and the glob,";
ok !$::{"\x{30cb}"}, "...but not the right one";

($const, $glob) =
  XS::APItest::newCONSTSUB_flags(\%::, "\x{30cd}", 0, undef);
ok $const, "newCONSTSUB_flags generates the constant,";
ok *{$glob}{CODE}, "..and the glob,";
ok $::{"\x{30cd}"}, "...the right one!";

eval q{
 BEGIN {
  no warnings;
  my $w;
  local $SIG{__WARN__} = sub { $w .= shift };
  *foo = sub(){123};
  newCONSTSUB_flags(\%::, "foo", 0, undef);
  is $w, undef, 'newCONSTSUB uses calling scope for redefinition warnings';
 }
};

{
 no strict 'refs';
 *{"foo::\x{100}"} = sub(){return 123};
 my $w;
 local $SIG{__WARN__} = sub { $w .= shift };
 newCONSTSUB_flags(\%foo::, "\x{100}", 0, undef);
 like $w, qr/Subroutine \x{100} redefined at /,
   'newCONSTSUB redefinition warning + utf8';
 undef $w;
 newCONSTSUB_flags(\%foo::, "\x{100}", 0, 54);
 like $w, qr/Constant subroutine \x{100} redefined at /,
   'newCONSTSUB constant redefinition warning + utf8';
}
