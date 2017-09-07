#!perl -T
use strict;
use Config;
use Test::More;

plan skip_all => "I18N::Langinfo or POSIX unavailable" 
    if $Config{'extensions'} !~ m!\bI18N/Langinfo\b!;

my @constants = qw(ABDAY_1 DAY_1 ABMON_1 MON_1 RADIXCHAR AM_STR THOUSEP D_T_FMT D_FMT T_FMT);

my %want =
    (
        ABDAY_1	=> "Sun",
        DAY_1	=> "Sunday",
        ABMON_1	=> "Jan",
        MON_1	=> "January",
        RADIXCHAR	=> ".",
        THOUSEP	=> "",
     );

my @want = sort keys %want;

plan tests => 1 + 3 * @constants + keys(@want);

use_ok('I18N::Langinfo', 'langinfo', @constants);

use POSIX;
setlocale(LC_ALL, "C");

for my $constant (@constants) {
    SKIP: {
        my $string = eval { langinfo(eval "$constant()") };
        is( $@, '', "calling langinfo() with $constant" );
        skip "returned string was empty, skipping next two tests", 2 unless $string;
        ok( defined $string, "checking if the returned string is defined" );
        cmp_ok( length($string), '>=', 1, "checking if the returned string has a positive length" );
    }
}

for my $i (1..@want) {
    my $try = $want[$i-1];
    eval { I18N::Langinfo->import($try) };
    SKIP: {
        skip "$try not defined", 1, if $@;
        no strict 'refs';
        is (langinfo(&$try), $want{$try}, "$try => '$want{$try}'");
    }
}
