#!perl -X

BEGIN {
    require Config; import Config;
    no warnings 'once';
    if ($Config{'extensions'} !~ /\bData\/Dumper\b/) {
	print "1..0 # Skip: Data::Dumper was not built\n";
	exit 0;
    }
}

use strict;
use Test::More tests => 2;
use Data::Dumper;

TODO: {
    local $TODO = "RT#58608: Data::Dumper and slashes within qr";
    my $q = q| \/ |;
    use Data::Dumper;
    my $qr = qr{$q};
    eval Dumper $qr;
    ok(!$@, "Dumping $qr with XS") or diag $@, Dumper $qr;
    local $Data::Dumper::Useperl = 1;
    eval Dumper $qr;
    ok(!$@, "Dumping $qr with PP") or diag $@, Dumper $qr;
}
