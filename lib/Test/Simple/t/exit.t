# Can't use Test.pm, that's a 5.005 thing.
package My::Test;

my $test_num = 1;
# Utility testing functions.
sub ok ($;$) {
    my($test, $name) = @_;
    my $ok = '';
    $ok .= "not " unless $test;
    $ok .= "ok $test_num";
    $ok .= " - $name" if defined $name;
    $ok .= "\n";
    print $ok;
    $test_num++;
}


package main;

my %Tests = (
             'success.plx'              => 0,
             'one_fail.plx'             => 1,
             'two_fail.plx'             => 2,
             'five_fail.plx'            => 5,
             'extras.plx'               => 3,
             'too_few.plx'              => 4,
             'death.plx'                => 255,
             'last_minute_death.plx'    => 255,
             'death_in_eval.plx'        => 0,
             'require.plx'              => 0,
            );

print "1..".keys(%Tests)."\n";

chdir 't' if -d 't';
use File::Spec;
my $lib = File::Spec->catdir('lib', 'Test', 'Simple', 'sample_tests');
while( my($test_name, $exit_code) = each %Tests ) {
    my $file = File::Spec->catfile($lib, $test_name);
    my $wait_stat = system(qq{$^X -"I../lib" -"Ilib/Test/Simple" $file});
    My::Test::ok( $wait_stat >> 8 == $exit_code, 
                  "$test_name exited with $exit_code" );
}


