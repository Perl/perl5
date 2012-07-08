use strict;
use warnings;
use Test::More;

use Socket qw(
    INADDR_ANY
    pack_ip_mreq unpack_ip_mreq
);

# Check that pack/unpack_ip_mreq either croak with "Not implemented", or
# roundtrip as identity

my $packed;
eval {
    $packed = pack_ip_mreq "\xe0\0\0\1", INADDR_ANY;
};
if( !defined $packed ) {
    plan skip_all => "No pack_ip_mreq" if $@ =~ m/ not implemented /;
    die $@;
}

plan tests => 3;

my @unpacked = unpack_ip_mreq $packed;

is( $unpacked[0], "\xe0\0\0\1", 'unpack_ip_mreq multiaddr' );
is( $unpacked[1], INADDR_ANY,   'unpack_ip_mreq interface' );

is( (unpack_ip_mreq pack_ip_mreq "\xe0\0\0\1")[1], INADDR_ANY, 'pack_ip_mreq interface defaults to INADDR_ANY' );
