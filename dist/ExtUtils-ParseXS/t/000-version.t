#!/usr/bin/perl
#
# Test that ExtUtils::ParseXS can load, and that its version
# matches that in perlxs.pod.

use strict;
use warnings;
use Test::More;
use File::Spec;
use lib (-d 't' ? File::Spec->catdir(qw(t lib)) : 'lib');

require_ok( 'ExtUtils::ParseXS' );

{
    my $file = $INC{"ExtUtils/ParseXS.pm"};
    $file=~s!ExtUtils/ParseXS\.pm\z!perlxs.pod!;
    open my $fh, "<", $file
        or die "Failed to open '$file' for read:$!";
    my $pod_version = "";
    while (defined(my $line= readline($fh))) {
        if ($line=~/\QThis document covers features supported by F<xsubpp> \E(\d+\.\d+)/) {
            $pod_version = $1;
            last;
        }
    }
    close $fh;
    ok($pod_version, "Found the version from perlxs.pod");
    is($pod_version, $ExtUtils::ParseXS::VERSION,
        "The version in perlxs.pod should match the version of ExtUtils::ParseXS");
}

done_testing;
