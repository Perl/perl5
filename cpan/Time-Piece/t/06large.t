use Test::More;
use Time::Piece;
use Time::Seconds;

# Large tests - test dates outside of the epoch range,
# somewhat silly, but lets see what happens

my $is_win32 = ( $^O =~ /Win32/ );

plan skip_all => "Large time tests not required for installation"
  unless ( $ENV{AUTOMATED_TESTING} || $ENV{NONINTERACTIVE_TESTING} || $ENV{PERL_BATCH} );

my $t = gmtime;

my $base_year = $t->year;
my $one_year  = ONE_YEAR;

for ( 1 .. 50 ) {
    $t = $t + $one_year;
    cmp_ok( $t->year, '==', $base_year + $_,
        "Year is: " . ( $base_year + $_ ) );
    cmp_ok(
        Time::Piece->strptime( $t->year . "-07-15 00:00:00", "%F %T" )->year,
        '==',
        $base_year + $_,
        "Strptime year is: " . ( $base_year + $_ )
    );
}

$t         = gmtime(1745187415);    # 20 Apr 2025 22:16:55
$base_year = $t->year;

$t = $t - ( $one_year * 25 );
cmp_ok( $t->year, '==', $base_year - 25, "Year is: " . ( $base_year - 25 ) );
cmp_ok(
    Time::Piece->strptime( $t->year . "-07-15 00:00:00", "%F %T" )->year,
    '==',
    $base_year - 25,
    "Strptime year is: " . ( $base_year - 25 )
);
$base_year -= 25;

$t = $t - ( $one_year * 25 );
cmp_ok( $t->year, '==', $base_year - 25, "Year is: " . ( $base_year - 25 ) );
cmp_ok(
    Time::Piece->strptime( $t->year . "-07-15 00:00:00", "%F %T" )->year,
    '==',
    $base_year - 25,
    "Strptime year is: " . ( $base_year - 25 )
);
$base_year -= 25;

SKIP: {
    skip "No time64 on Win32 if perl < 5.12", 12, if $is_win32 && $] < 5.012;

    for ( 1 .. 6 ) {
        $t = $t - ( $one_year * 25 );
        cmp_ok(
            $t->year, '==',
            $base_year - 25,
            "Year is: " . ( $base_year - 25 )
        );
        cmp_ok(
            Time::Piece->strptime( $t->year . "-07-15 00:00:00", "%F %T" )
              ->year,
            '==',
            $base_year - 25,
            "Strptime year is: " . ( $base_year - 25 )
        );

        $base_year -= 25;

    }

}

done_testing(116);
