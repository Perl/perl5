BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    use File::Spec;
}

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

my $IsVMS = $^O eq 'VMS';

print "# Ahh!  I see you're running VMS.\n" if $IsVMS;

my %Tests = (
             #                      Everyone Else   VMS
             'success.plx'              => [0,      0],
             'one_fail.plx'             => [1,      4],
             'two_fail.plx'             => [2,      4],
             'five_fail.plx'            => [5,      4],
             'extras.plx'               => [3,      4],
             'too_few.plx'              => [4,      4],
             'death.plx'                => [255,    4],
             'last_minute_death.plx'    => [255,    4],
             'death_in_eval.plx'        => [0,      0],
             'require.plx'              => [0,      0],
            );

print "1..".keys(%Tests)."\n";

my $lib = File::Spec->catdir('lib', 'Test', 'Simple', 'sample_tests');

while( my($test_name, $exit_codes) = each %Tests ) {
    my($exit_code) = $exit_codes->[$IsVMS ? 1 : 0];

    my $file = File::Spec->catfile($lib, $test_name);

    my $wait_stat = system(qq{$^X -"I../lib" -"I../t/lib" $file});
    my $actual_exit = $wait_stat >> 8;

    My::Test::ok( $actual_exit == $exit_code, 
                  "$test_name exited with $actual_exit (expected $exit_code)");
}
