#!/usr/bin/perl -w

use Test::More;
plan skip_all => "POD tests skipped unless AUTHOR_TESTING is set" unless $ENV{AUTHOR_TESTING};
my $test_pod = eval "use Test::Pod 1.00; 1";
plan skip_all => "Test::Pod 1.00 required for testing POD" unless $test_pod;
all_pod_files_ok();
