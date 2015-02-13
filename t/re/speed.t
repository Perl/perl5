#!./perl
#
# This is a home for regular expression tests that don't fit into
# the format supported by re/regexp.t, that specifically should run fast.
#
# All the tests in this file are ones that run exceptionally slowly
# (each test taking seconds or even minutes) in the absence of particular
# optimisations. Thus it is a sort of canary for optimisations being
# broken.
#
# Although it includes a watchdog timeout, this is set to a generous limit
# to allow for running on slow systems; therefore a broken optimisation
# might be indicated merely by this test file taking unusually long to
# run, rather than actually timing out.
#

BEGIN {
    chdir 't' if -d 't';
    @INC = ('../lib','.','../ext/re');
    require Config; import Config;
    require './test.pl';
    skip_all('no re module') unless defined &DynaLoader::boot_DynaLoader;
    skip_all_without_unicode_tables();
}

plan tests => 25;  # Update this when adding/deleting tests.

use strict;
use warnings;
use 5.010;

sub run_tests;

$| = 1;

run_tests() unless caller;

#
# Tests start here.
#
sub run_tests {


    watchdog(($::running_as_thread && $::running_as_thread) ? 50 : 75);

    {
        # [perl #120446]
        # this code should be virtually instantaneous. If it takes 10s of
        # seconds, there a bug in intuit_start.
        # (this test doesn't actually test for slowness - that involves
        # too much danger of false positives on loaded machines - but by
        # putting it here, hopefully someone might notice if it suddenly
        # runs slowly)
        my $s = ('a' x 1_000_000) . 'b';
        my $i = 0;
        for (1..10_000) {
            pos($s) = $_;
            $i++ if $s =~/\Gb/g;
        }
        is($i, 0, "RT 120446: mustn't run slowly");
    }

    {
        # [perl #120692]
        # these tests should be virtually instantaneous. If they take 10s of
        # seconds, there's a bug in intuit_start.

        my $s = 'ab' x 1_000_000;
        utf8::upgrade($s);
        1 while $s =~ m/\Ga+ba+b/g;
        pass("RT#120692 \\G mustn't run slowly");

        $s=~ /^a{1,2}x/ for  1..10_000;
        pass("RT#120692 a{1,2} mustn't run slowly");

        $s=~ /ab.{1,2}x/;
        pass("RT#120692 ab.{1,2} mustn't run slowly");

        $s = "-a-bc" x 250_000;
        $s .= "1a1bc";
        utf8::upgrade($s);
        ok($s =~ /\da\d{0,30000}bc/, "\\d{30000}");

        $s = "-ab\n" x 250_000;
        $s .= "abx";
        ok($s =~ /^ab.*x/m, "distant float with /m");

        my $r = qr/^abcd/;
        $s = "abcd-xyz\n" x 500_000;
        $s =~ /$r\d{1,2}xyz/m for 1..200;
        pass("BOL within //m  mustn't run slowly");

        $s = "abcdefg" x 1_000_000;
        $s =~ /(?-m:^)abcX?fg/m for 1..100;
        pass("BOL within //m  mustn't skip absolute anchored check");

        $s = "abcdefg" x 1_000_000;
        $s =~ /^XX\d{1,10}cde/ for 1..100;
        pass("abs anchored float string should fail quickly");

        # if /.*.../ fails to be optimised well (PREGf_IMPLICIT),
        # things tend to go quadratic (RT #123743)

        $s = ('0' x 200_000) . '::: 0c';
        ok ($s !~ /.*:::\s*ab/,    'PREGf_IMPLICIT');
        ok ($s !~ /.*:::\s*ab/i,   'PREGf_IMPLICIT/i');
        ok ($s !~ /.*:::\s*ab/m,   'PREGf_IMPLICIT/m');
        ok ($s !~ /.*:::\s*ab/mi,  'PREGf_IMPLICIT/mi');
        ok ($s !~ /.*:::\s*ab/s,   'PREGf_IMPLICIT/s');
        ok ($s !~ /.*:::\s*ab/si,  'PREGf_IMPLICIT/si');
        ok ($s !~ /.*:::\s*ab/ms,  'PREGf_IMPLICIT/ms');
        ok ($s !~ /.*:::\s*ab/msi, 'PREGf_IMPLICIT/msi');
        ok ($s !~ /.*?:::\s*ab/,   'PREGf_IMPLICIT');
        ok ($s !~ /.*?:::\s*ab/i,  'PREGf_IMPLICIT/i');
        ok ($s !~ /.*?:::\s*ab/m,  'PREGf_IMPLICIT/m');
        ok ($s !~ /.*?:::\s*ab/mi, 'PREGf_IMPLICIT/mi');
        ok ($s !~ /.*?:::\s*ab/s,  'PREGf_IMPLICIT/s');
        ok ($s !~ /.*?:::\s*ab/si, 'PREGf_IMPLICIT/si');
        ok ($s !~ /.*?:::\s*ab/ms, 'PREGf_IMPLICIT/ms');
        ok ($s !~ /.*?:::\s*ab/msi,'PREGf_IMPLICIT/msi');
    }

} # End of sub run_tests

1;
