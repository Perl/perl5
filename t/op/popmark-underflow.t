#!./perl

use strict;
use warnings;

require './test.pl';

my $poc_min = '\(sort {0} 0, 0 .. "r")';

my $poc_fuzz = <<'POC';
\(\(\(\(\(\(\(\(sort {
    \(\(sort {18446605494517776183;} %0, 'so'));
} %0 = 'Ev5' .. 14))))))));
POC

my @pocs = (
    [ 'minimal', $poc_min ],
    [ 'fuzz',    $poc_fuzz ],
);

my $libdir = -d 'lib' ? 'lib' : '../lib';
my $runperl_args = {
    nolib    => 1,
    switches => [ "-I$libdir" ],
};

for my $case (@pocs) {
    my ($name, $poc) = @$case;
    my $err = fresh_perl($poc, $runperl_args);
    my $status = $?;

    unlike($err, qr/Segmentation fault/, "$name: no segfault");
    like($err, qr/\bpanic:\s+MARK underflow\b/, "$name: deterministic MARK underflow");

}

done_testing();
