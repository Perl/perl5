#
# $Id: Encoder.t,v 1.1 2002/04/08 18:07:31 dankogai Exp $
#

BEGIN {
    require Config; import Config;
    if ($Config{'extensions'} !~ /\bEncode\b/) {
      print "1..0 # Skip: Encode was not built\n";
      exit 0;
    }
# should work without perlio
#     unless (find PerlIO::Layer 'perlio') {
# 	print "1..0 # Skip: PerlIO was not built\n";
# 	exit 0;
#     }
# should work on EBCDIC
#    if (ord("A") == 193) {
# 	print "1..0 # Skip: EBCDIC\n";
# 	exit 0;
#    }
    $| = 1;
}

use strict;
#use Test::More 'no_plan';
use Test::More tests => 512;
use Encode::Encoder;
use MIME::Base64;
package Encode::Base64;
use base 'Encode::Encoding';
__PACKAGE__->Define('base64');
use MIME::Base64;
sub encode{
    my ($obj, $data) = @_;
    return encode_base64($data);
}
sub decode{
    my ($obj, $data) = @_;
    return decode_base64($data);
}

package main;

my $data = '';
for my $i (0..255){
    no warnings;
    $data .= chr($i);
    my $base64 = encode_base64($data);
    is(encoder($data)->base64, $base64, "encode");
    is(encoder($base64)->bytes('base64'), $data, "decode");
}

1;
__END__
