#!perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;

# For shutting up Test::Harness.
package My::Dev::Null;
use Tie::Handle;
@My::Dev::Null::ISA = qw(Tie::StdHandle);

sub WRITE { }


package main;

# Utility testing functions.
my $test_num = 1;
sub ok ($;$) {
    my($test, $name) = @_;
    my $okstring = '';
    $okstring = "not " unless $test;
    $okstring .= "ok $test_num";
    $okstring .= " - $name" if defined $name;
    print "$okstring\n";
    $test_num++;
}

sub eqhash {
    my($a1, $a2) = @_;
    return 0 unless keys %$a1 == keys %$a2;

    my $ok = 1;
    foreach my $k (keys %$a1) {
        $ok = $a1->{$k} eq $a2->{$k};
        last unless $ok;
    }

    return $ok;
}

use vars qw($Total_tests %samples);

my $loaded;
BEGIN { $| = 1; $^W = 1; }
END {print "not ok $test_num\n" unless $loaded;}
print "1..$Total_tests\n";
use Test::Harness;
$loaded = 1;
ok(1, 'compile');
######################### End of black magic.

BEGIN {
    %samples = (
                simple            => {
                                      bonus      => 0,
                                      max        => 5,
                                      'ok'         => 5,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
                simple_fail      => {
                                     bonus       => 0,
                                     max         => 5,
                                     'ok'          => 3,
                                     files       => 1,
                                     bad         => 1,
                                     good        => 0,
                                     tests       => 1,
                                     sub_skipped => 0,
                                     skipped     => 0,
                                    },
                descriptive       => {
                                      bonus      => 0,
                                      max        => 5,
                                      'ok'         => 5,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
                no_nums           => {
                                      bonus      => 0,
                                      max        => 5,
                                      'ok'         => 4,
                                      files      => 1,
                                      bad        => 1,
                                      good       => 0,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
                todo              => {
                                      bonus      => 1,
                                      max        => 5,
                                      'ok'         => 5,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
                skip              => {
                                      bonus      => 0,
                                      max        => 5,
                                      'ok'         => 5,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 1,
                                      skipped    => 0,
                                     },
                bailout           => 0,
                combined          => {
                                      bonus      => 1,
                                      max        => 10,
                                      'ok'         => 8,
                                      files      => 1,
                                      bad        => 1,
                                      good       => 0,
                                      tests      => 1,
                                      sub_skipped=> 1,
                                      skipped    => 0
                                     },
                duplicates        => {
                                      bonus      => 0,
                                      max        => 10,
                                      'ok'         => 11,
                                      files      => 1,
                                      bad        => 1,
                                      good       => 0,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
                header_at_end     => {
                                      bonus      => 0,
                                      max        => 4,
                                      'ok'         => 4,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
                skip_all          => {
                                      bonus      => 0,
                                      max        => 0,
                                      'ok'         => 0,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 1,
                                     },
                with_comments     => {
                                      bonus      => 2,
                                      max        => 5,
                                      'ok'         => 5,
                                      files      => 1,
                                      bad        => 0,
                                      good       => 1,
                                      tests      => 1,
                                      sub_skipped=> 0,
                                      skipped    => 0,
                                     },
               );

    $Total_tests = keys(%samples) + 1;
}

tie *NULL, 'My::Dev::Null' or die $!;

while (my($test, $expect) = each %samples) {
    # _run_all_tests() runs the tests but skips the formatting.
    my($totals, $failed);
    eval {
        select NULL;    # _run_all_tests() isn't as quiet as it should be.
        ($totals, $failed) = 
          Test::Harness::_run_all_tests("lib/sample-tests/$test");
    };
    select STDOUT;

    unless( $@ ) {
        ok( eqhash( $expect, {map { $_=>$totals->{$_} } keys %$expect} ), 
                                                                      $test );
    }
    else {      # special case for bailout
        ok( ($test eq 'bailout' and $@ =~ /Further testing stopped: GERONI/i),
            $test );
    }
}
