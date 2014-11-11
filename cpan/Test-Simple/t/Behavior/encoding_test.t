use strict;
use warnings;
no utf8;

# line 5 "encoding_tést.t"

use Test::Stream;
use Test::More;
use Test::Stream::Tester;

BEGIN {
    my $norm = eval { require Unicode::Normalize; require Encode; 1 };
    plan skip_all => 'Unicode::Normalize is required for this test' unless $norm;
}

my $filename = __FILE__;
ok(!utf8::is_utf8($filename), "filename is not in utf8 yet");
my $utf8name = Unicode::Normalize::NFKC(Encode::decode('utf8', "$filename", Encode::FB_CROAK));
ok( $filename ne $utf8name, "sanity check" );

my $scoper = sub { context()->snapshot };

tap_encoding 'utf8';
my $ctx_utf8 = $scoper->();

tap_encoding 'legacy';
my $ctx_legacy = $scoper->();

is($ctx_utf8->encoding,   'utf8',   "got a utf8 context");
is($ctx_legacy->encoding, 'legacy', "got a legacy context");

is($ctx_utf8->file, $utf8name, "Got utf8 name");
is($ctx_legacy->file, $filename, "Got legacy name");

done_testing;
