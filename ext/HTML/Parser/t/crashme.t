#!/usr/bin/perl

# This test will simply run the parser on random junk.

my $no_tests = shift || 3;
use Test::More;
plan tests => $no_tests;

use HTML::Parser ();

my $file = "junk$$.html";
die if -e $file;

for (1..$no_tests) {

    open(JUNK, ">$file") || die;
    for (1 .. rand(5000)) {
        for (1 .. rand(200)) {
            print JUNK pack("N", rand(2**32));
        }
        print JUNK ("<", "&", ">")[rand(3)];  # make these a bit more likely
    }
    close(JUNK);

    #diag "Parse @{[-s $file]} bytes of junk";

    HTML::Parser->new->parse_file($file);
    pass();

    #print_mem();
}

unlink($file);


sub print_mem
{
    # this probably only works on Linux
    open(STAT, "/proc/self/status") || return;
    while (<STAT>) {
        diag $_ if /^VmSize/;
    }
}
