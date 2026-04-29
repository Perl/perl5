use strict;
use warnings;
use Test::More;
use JSON::PP;

plan tests => 3;

# from GH#61

sub MyClass::new { bless {}, shift }
sub MyClass::TO_JSON { encode_json([]) }

ok my $json = JSON::PP->new->convert_blessed;
is $json->encode([MyClass->new]) => '["[]"]';
my $res = eval { $json->encode([MyClass->new, MyClass->new]) };
is $res => '["[]","[]"]';
