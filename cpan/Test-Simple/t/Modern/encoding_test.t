use strict;
use warnings;
no utf8;

use Test::More qw/modern/;
use Test::Tester2;

BEGIN {
    my $norm = eval { require Unicode::Normalize; require Encode; 1 };
    plan skip_all => 'Unicode::Normalize is required for this test' unless $norm;
}

my $filename = "encoding_tést.t";
ok(!utf8::is_utf8($filename), "filename is not in utf8 already");
my $utf8name = Unicode::Normalize::NFKC(Encode::decode('utf8', "$filename", Encode::FB_CROAK));
ok( $filename ne $utf8name, "sanity check" );

tap_encoding 'utf8';
my $trace_utf8 = Test::Builder::Trace->new();
$trace_utf8->report->file($filename);

tap_encoding 'legacy';
my $trace_legacy = Test::Builder::Trace->new();
$trace_legacy->report->file($filename);

is($trace_utf8->encoding, 'utf8', "got a utf8 trace");
is($trace_legacy->encoding, 'legacy', "got a legacy trace");

my $diag_utf8 = Test::Builder::Result::Diag->new(
    message => "failed blah de blah\nFatal error in $filename line 42.\n",
    trace   => $trace_utf8,
);

my $diag_legacy = Test::Builder::Result::Diag->new(
    message => "failed blah de blah\nFatal error in $filename line 42.\n",
    trace   => $trace_legacy,
);

ok( $diag_legacy->to_tap ne $diag_utf8->to_tap, "The utf8 diag has a different output" );

is(
    $diag_legacy->to_tap,
    "# failed blah de blah\n# Fatal error in $filename line 42.\n",
    "Got unaltered filename in legacy"
);

# Change encoding for the scope of the next test so that errors make more sense.
tap_encoding 'utf8' => sub {
    is(
        $diag_utf8->to_tap,
        "# failed blah de blah\n# Fatal error in $utf8name line 42.\n",
        "Got transcoded filename in utf8"
    );
};

{
    my $file = __FILE__;
    my $success = eval { tap_encoding 'invalid_encoding'; 1 }; my $line = __LINE__;
    chomp(my $error = $@);
    ok(!$success, "Threw an exception when using invalid encoding");
    like($error, qr/^encoding 'invalid_encoding' is not valid, or not available at $file line $line/, 'validate encoding');
};



done_testing;
