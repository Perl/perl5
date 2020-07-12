#!perl -w

use Test::More tests => 10;

BEGIN {
    use_ok('XS::APItest');

    my $lib = $^X;
    $lib =~ s{(\b)perl[^/]*$}{${1}lib};

    my $t = $^X;
    $t =~ s{(\b)perl[^/]*$}{${1}t};
    local @INC = ( $lib, $t );

    require 'charset_tools.pl';
};

my $b = "\303\244"; # or encode_utf8("\x{e4}");

is(XS::APItest::first_byte($b), 0303,
    "test function first_byte works");

$b =~ /(.)/;
is(XS::APItest::first_byte($1), 0303,
    "matching works correctly");

my $a = qq[\x{263a}]; # utf8 flag is set

$a =~ s/(.)/$1/;      # $1 now has the utf8 flag set too
$b =~ /(.)/;          # $1 shouldn't have the utf8 flag anymore

is(XS::APItest::first_byte("$1"), 0303,
    "utf8 flag in match fetched correctly when stringified first");

$a =~ s/(.)/$1/;      # $1 now has the utf8 flag set too
$b =~ /(.)/;          # $1 shouldn't have the utf8 flag anymore

is(eval { XS::APItest::first_byte($1) } || $@, 0303,
    "utf8 flag fetched correctly without stringification");

my $f;
sub TIESCALAR { bless [], shift }
sub FETCH { ++$f; no strict 'refs'; *{chr utf8::unicode_to_native(255)} }
tie my  $t, "main";
is SvPVutf8($t), "*main::" . byte_utf8a_to_utf8n("\xc3\xbf"),
  'SvPVutf8 works with get-magic changing the SV type';
is $f, 1, 'SvPVutf8 calls get-magic once';

package t {
  our @ISA = 'main';
  no warnings 'once';
  sub FETCH { ++$::f; chr utf8::unicode_to_native(255) }
  sub STORE { }
}
tie $t, "t";
undef $f;
is SvPVutf8($t), byte_utf8a_to_utf8n("\xc3\xbf"),
  'SvPVutf8 works with get-magic downgrading the SV';
is $f, 1, 'SvPVutf8 calls get-magic once';
()="$t";
is $f, 2, 'SvPVutf8 does not stop stringification from calling FETCH';
