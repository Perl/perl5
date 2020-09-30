#!perl -X

use strict;
use warnings;

use Config;

BEGIN {
    if ($Config{'extensions'} !~ /\bData\/Dumper\b/) {
        print "1..0 # Skip: Data::Dumper was not built\n";
        exit 0;
    }
}

use Test::More tests => 2;
use Data::Dumper;

{
    my $q = q| \/ |;
    use Data::Dumper;
    my $qr = qr{$q};
    eval add_my_to_dump( Dumper $qr );
    ok(!$@, "Dumping $qr with XS") or diag $@, Dumper $qr;
    local $Data::Dumper::Useperl = 1;
    eval add_my_to_dump( Dumper $qr );
    ok(!$@, "Dumping $qr with PP") or diag $@, Dumper $qr;
}

sub add_my_to_dump {
    $_[0] =~ s{^(\s*)(\$VAR)}{$1 my $2}mg;

    return $_[0];
}
