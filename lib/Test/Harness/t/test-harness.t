#!perl

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
}

use strict;

# For shutting up Test::Harness.
# Has to work on 5.004, which doesn't have Tie::StdHandle.
package My::Dev::Null;

sub WRITE  {}
sub PRINT  {}
sub PRINTF {}
sub TIEHANDLE {
    my $class = shift;
    my $fh    = do { local *HANDLE;  \*HANDLE };
    return bless $fh, $class;
}
sub READ {}
sub READLINE {}
sub GETC {}


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
                                      total => {
                                                bonus      => 0,
                                                max        => 5,
                                                'ok'       => 5,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                simple_fail      => {
                                     total => {
                                               bonus       => 0,
                                               max         => 5,
                                               'ok'        => 3,
                                               files       => 1,
                                               bad         => 1,
                                               good        => 0,
                                               tests       => 1,
                                               sub_skipped => 0,
                                               todo        => 0,
                                               skipped     => 0,
                                              },
                                     failed => {
                                                canon      => '2 5',
                                               },
                                     all_ok => 0,
                                    },
                descriptive       => {
                                      total => {
                                                bonus      => 0,
                                                max        => 5,
                                                'ok'       => 5,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                no_nums           => {
                                      total => {
                                                bonus      => 0,
                                                max        => 5,
                                                'ok'       => 4,
                                                files      => 1,
                                                bad        => 1,
                                                good       => 0,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => {
                                                 canon     => '3',
                                                },
                                      all_ok => 0,
                                     },
                todo              => {
                                      total => {
                                                bonus      => 1,
                                                max        => 5,
                                                'ok'       => 5,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 2,
                                                skipped    => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                todo_inline       => {
                                      total => {
                                                bonus       => 1,
                                                max         => 3,
                                                'ok'        => 3,
                                                files       => 1,
                                                bad         => 0,
                                                good        => 1,
                                                tests       => 1,
                                                sub_skipped => 0,
                                                todo        => 2,
                                                skipped     => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                skip              => {
                                      total => {
                                                bonus      => 0,
                                                max        => 5,
                                                'ok'       => 5,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 1,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                bailout           => 0,
                combined          => {
                                      total => {
                                                bonus      => 1,
                                                max        => 10,
                                                'ok'       => 8,
                                                files      => 1,
                                                bad        => 1,
                                                good       => 0,
                                                tests      => 1,
                                                sub_skipped=> 1,
                                                todo       => 2,
                                                skipped    => 0
                                               },
                                      failed => {
                                                 canon     => '3 9',
                                                },
                                      all_ok => 0,
                                     },
                duplicates        => {
                                      total => {
                                                bonus      => 0,
                                                max        => 10,
                                                'ok'       => 11,
                                                files      => 1,
                                                bad        => 1,
                                                good       => 0,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => {
                                                 canon     => '??',
                                                },
                                      all_ok => 0,
                                     },
                head_end          => {
                                      total => {
                                                bonus      => 0,
                                                max        => 4,
                                                'ok'       => 4,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                head_fail         => {
                                      total => {
                                                bonus      => 0,
                                                max        => 4,
                                                'ok'       => 3,
                                                files      => 1,
                                                bad        => 1,
                                                good       => 0,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 0,
                                               },
                                      failed => {
                                                 canon      => '2',
                                                },
                                      all_ok => 0,
                                     },
                skip_all          => {
                                      total => {
                                                bonus      => 0,
                                                max        => 0,
                                                'ok'       => 0,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 0,
                                                skipped    => 1,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
                with_comments     => {
                                      total => {
                                                bonus      => 2,
                                                max        => 5,
                                                'ok'       => 5,
                                                files      => 1,
                                                bad        => 0,
                                                good       => 1,
                                                tests      => 1,
                                                sub_skipped=> 0,
                                                todo       => 4,
                                                skipped    => 0,
                                               },
                                      failed => { },
                                      all_ok => 1,
                                     },
               );

    $Total_tests = (keys(%samples) * 4);
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
        ok( Test::Harness::_all_ok($totals) == $expect->{all_ok},    
                                                      "$test - all ok" );
        ok( defined $expect->{total},                 "$test - has total" );
        ok( eqhash( $expect->{total}, 
                    {map { $_=>$totals->{$_} } keys %{$expect->{total}}} ),
                                                         "$test - totals" );
        ok( eqhash( $expect->{failed}, 
                    {map { $_=>$failed->{"lib/sample-tests/$test"}{$_} }
                              keys %{$expect->{failed}}} ),
                                                         "$test - failed" );
    }
    else {      # special case for bailout
        ok( ($test eq 'bailout' and $@ =~ /Further testing stopped: GERONI/i),
            $test );
        ok( 1,  'skipping for bailout' );
        ok( 1,  'skipping for bailout' );
    }
}
