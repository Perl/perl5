#!./perl

use strict;
use warnings;
use Config; # to determine nvsize
use Test::More tests => 39;
use List::Util qw( uniqnum uniqstr uniq );

use Tie::Array;

is_deeply( [ uniqstr ],
           [],
           'uniqstr of empty list' );

is_deeply( [ uniqstr qw( abc ) ],
           [qw( abc )],
           'uniqstr of singleton list' );

is_deeply( [ uniqstr qw( x x x ) ],
           [qw( x )],
           'uniqstr of repeated-element list' );

is_deeply( [ uniqstr qw( a b a c ) ],
           [qw( a b c )],
           'uniqstr removes subsequent duplicates' );

is_deeply( [ uniqstr qw( 1 1.0 1E0 ) ],
           [qw( 1 1.0 1E0 )],
           'uniqstr compares strings' );

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    is_deeply( [ uniqstr "", undef ],
               [ "" ],
               'uniqstr considers undef and empty-string equivalent' );

    ok( length $warnings, 'uniqstr on undef yields a warning' );

    is_deeply( [ uniqstr undef ],
               [ "" ],
               'uniqstr on undef coerces to empty-string' );
}

SKIP: {
    skip 'Perl 5.007003 with utf8::encode is required', 3 if $] lt "5.007003";
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    my $cafe = "cafe\x{301}";

    is_deeply( [ uniqstr $cafe ],
               [ $cafe ],
               'uniqstr is happy with Unicode strings' );

    SKIP: {
      skip "utf8::encode not available", 1
        unless defined &utf8::encode;
      utf8::encode( my $cafebytes = $cafe );

      is_deeply( [ uniqstr $cafe, $cafebytes ],
                [ $cafe, $cafebytes ],
                'uniqstr does not squash bytewise-equal but differently-encoded strings' );
    }

    is( $warnings, "", 'No warnings are printed when handling Unicode strings' );
}

is_deeply( [ uniqnum qw( 1 1.0 1E0 2 3 ) ],
           [ 1, 2, 3 ],
           'uniqnum compares numbers' );

is_deeply( [ uniqnum qw( 1 1.1 1.2 1.3 ) ],
           [ 1, 1.1, 1.2, 1.3 ],
           'uniqnum distinguishes floats' );

{
    my @nums = map $_+0.1, 1e7..1e7+5;
    is_deeply( [ uniqnum @nums ],
               [ @nums ],
               'uniqnum distinguishes large floats' );

    my @strings = map "$_", @nums;
    is_deeply( [ uniqnum @strings ],
               [ @strings ],
               'uniqnum distinguishes large floats (stringified)' );
}

my ($uniq_count1, $uniq_count2, $equiv);

if($Config{nvsize} == 8) {
  # NV is either 'double' or 8-byte 'long double'

  # The 2 values should be unequal - but just in case perl is buggy:
  $equiv = 1 if 1.4142135623730951 == 1.4142135623730954;

  $uniq_count1 = uniqnum (1.4142135623730951,
                          1.4142135623730954 );

  $uniq_count2 = uniqnum('1.4142135623730951',
                         '1.4142135623730954' );
}

elsif(length(sqrt(2)) > 25) {
  # NV is either IEEE 'long double' or '__float128' or doubledouble

  if(1 + (2 ** -1074) != 1) {
    # NV is doubledouble

    # The 2 values should be unequal - but just in case perl is buggy:
    $equiv = 1 if 1 + (2 ** -1074) == 1 + (2 ** - 1073);

    $uniq_count1 = uniqnum (1 + (2 ** -1074),
                            1 + (2 ** -1073) );
    # The 2 values should be unequal - but just in case perl is buggy:
    $equiv = 1 if 4.0564819207303340847894502572035e31 == 4.0564819207303340847894502572034e31;

    $uniq_count2 = uniqnum('4.0564819207303340847894502572035e31',
                           '4.0564819207303340847894502572034e31' );
  }

  else {
    # NV is either IEEE 'long double' or '__float128'

    # The 2 values should be unequal - but just in case perl is buggy:
    $equiv = 1 if 1.7320508075688772935274463415058722 == 1.73205080756887729352744634150587224;

    $uniq_count1 = uniqnum (1.7320508075688772935274463415058722,
                            1.73205080756887729352744634150587224 );

    $uniq_count2 = uniqnum('1.7320508075688772935274463415058722',
                           '1.73205080756887729352744634150587224' );
  }
}

else {
  # NV is extended precision 'long double'

  # The 2 values should be unequal - but just in case perl is buggy:
  $equiv = 1 if 2.2360679774997896963 == 2.23606797749978969634;

  $uniq_count1 = uniqnum (2.2360679774997896963,
                          2.23606797749978969634 );

  $uniq_count2 = uniqnum('2.2360679774997896963',
                         '2.23606797749978969634' );
}

if($equiv) {
  is($uniq_count1, 1, 'uniqnum preserves uniqueness of high precision floats');
  is($uniq_count2, 1, 'uniqnum preserves uniqueness of high precision floats (stringified)');
}

else {
  is($uniq_count1, 2, 'uniqnum preserves uniqueness of high precision floats');
  is($uniq_count2, 2, 'uniqnum preserves uniqueness of high precision floats (stringified)');
}

SKIP: {
    skip ('test not relevant for this perl configuration', 1) unless $Config{nvsize} == 8
                                                                  && $Config{ivsize} == 8;

    my @in = (~0, ~0 - 1, 18446744073709551614.0, 18014398509481985, 1.8014398509481985e16);
    my(@correct);

    # On perl-5.6.2 (and perhaps other old versions), ~0 - 1 is assigned to an NV.
    # This affects the outcome of the following test, so we need to first determine
    # whether ~0 - 1 is an NV or a UV:

    if("$in[1]" eq "1.84467440737096e+19") {

      # It's an NV and $in[2] is a duplicate of $in[1]
      @correct = (~0, ~0 - 1, 18014398509481985, 1.8014398509481985e16);
    }
    else {

      # No duplicates in @in
      @correct = @in;
    }

    is_deeply( [ uniqnum @in ],
               [ @correct ],
               'uniqnum correctly compares UV/IVs that overflow NVs' );
}

my $ls = 31;
if($Config{ivsize} == 8) { $ls = 63 }

is_deeply( [ uniqnum ( 1 << $ls, 2 ** $ls,
                       1 << ($ls - 3), 2 ** ($ls - 3),
                       5 << ($ls - 3), 5 * (2 ** ($ls - 3))) ],
           [ 1 << $ls, 1 << ($ls - 3), 5 << ($ls -3) ],
           'uniqnum correctly compares UV/IVs that don\'t overflow NVs' );

# Hard to know for sure what an Inf is going to be. Lets make one
my $Inf = 0 + 1E1000;
my $NaN;
$Inf **= 1000 while ( $NaN = $Inf - $Inf ) == $NaN;

is_deeply( [ uniqnum 0, 1, 12345, $Inf, -$Inf, $NaN, 0, $Inf, $NaN ],
           [ 0, 1, 12345, $Inf, -$Inf, $NaN ],
           'uniqnum preserves the special values of +-Inf and Nan' );

SKIP: {
    my $maxuint = ~0;
    my $maxint = ~0 >> 1;
    my $minint = -(~0 >> 1) - 1;

    my @nums = ($maxuint, $maxuint-1, -1, $maxint, $minint, 1 );

    {
        use warnings FATAL => 'numeric';
        if (eval {
            "$Inf" + 0 == $Inf
        }) {
            push @nums, $Inf;
        }
        if (eval {
            my $nanish = "$NaN" + 0;
            $nanish != 0 && !$nanish != $NaN;
        }) {
            push @nums, $NaN;
        }
    }

    is_deeply( [ uniqnum @nums, 1.0 ],
               [ @nums ],
               'uniqnum preserves uniqueness of full integer range' );

    my @strs = map "$_", @nums;

    if($maxuint !~ /\A[0-9]+\z/) {
      skip( "Perl $] doesn't stringify UV_MAX right ($maxuint)", 1 );
    }

    is_deeply( [ uniqnum @strs, "1.0" ],
               [ @strs ],
               'uniqnum preserves uniqueness of full integer range (stringified)' );
}

{
    my @nums = (6.82132005170133e-38, 62345678);
    is_deeply( [ uniqnum @nums ], [ @nums ],
        'uniqnum keeps uniqueness of numbers that stringify to the same byte pattern as a float'
    );
}

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    is_deeply( [ uniqnum 0, undef ],
               [ 0 ],
               'uniqnum considers undef and zero equivalent' );

    ok( length $warnings, 'uniqnum on undef yields a warning' );

    is_deeply( [ uniqnum undef ],
               [ 0 ],
               'uniqnum on undef coerces to zero' );
}

is_deeply( [uniqnum 0, -0.0 ],
           [0],
           'uniqnum handles negative zero');

is_deeply( [ uniq () ],
           [],
           'uniq of empty list' );

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    is_deeply( [ uniq "", undef ],
               [ "", undef ],
               'uniq distintinguishes empty-string from undef' );

    is_deeply( [ uniq undef, undef ],
               [ undef ],
               'uniq considers duplicate undefs as identical' );

    ok( !length $warnings, 'uniq on undef does not warn' );
}

is( scalar( uniqstr qw( a b c d a b e ) ), 5, 'uniqstr() in scalar context' );

{
    package Stringify;

    use overload '""' => sub { return $_[0]->{str} };

    sub new { bless { str => $_[1] }, $_[0] }

    package main;

    my @strs = map { Stringify->new( $_ ) } qw( foo foo bar );

    is_deeply( [ map "$_", uniqstr @strs ],
               [ map "$_", $strs[0], $strs[2] ],
               'uniqstr respects stringify overload' );
}

{
    package Numify;

    use overload '0+' => sub { return $_[0]->{num} };

    sub new { bless { num => $_[1] }, $_[0] }

    package main;
    use Scalar::Util qw( refaddr );

    my @nums = map { Numify->new( $_ ) } qw( 2 2 5 );

    # is_deeply wants to use eq overloading
    my @ret = uniqnum @nums;
    ok( scalar @ret == 2 &&
        refaddr $ret[0] == refaddr $nums[0] &&
        refaddr $ret[1] == refaddr $nums[2],
               'uniqnum respects numify overload' );
}

{
    package DestroyNotifier;

    use overload '""' => sub { "SAME" };

    sub new { bless { var => $_[1] }, $_[0] }

    sub DESTROY { ${ $_[0]->{var} }++ }

    package main;

    my @destroyed = (0) x 3;
    my @notifiers = map { DestroyNotifier->new( \$destroyed[$_] ) } 0 .. 2;

    my @uniqstr = uniqstr @notifiers;
    undef @notifiers;

    is_deeply( \@destroyed, [ 0, 1, 1 ],
               'values filtered by uniqstr() are destroyed' );

    undef @uniqstr;
    is_deeply( \@destroyed, [ 1, 1, 1 ],
               'all values destroyed' );
}

{
    "a a b" =~ m/(.) (.) (.)/;
    is_deeply( [ uniqstr $1, $2, $3 ],
               [qw( a b )],
               'uniqstr handles magic' );

    "1 1 2" =~ m/(.) (.) (.)/;
    is_deeply( [ uniqnum $1, $2, $3 ],
               [ 1, 2 ],
               'uniqnum handles magic' );
}

{
    my @array;
    tie @array, 'Tie::StdArray';
    @array = (
        ( map { ( 1 .. 10 ) } 0 .. 1 ),
        ( map { ( 'a' .. 'z' ) } 0 .. 1 )
    );

    my @u = uniq @array;
    is_deeply(
        \@u,
        [ 1 .. 10, 'a' .. 'z' ],
        'uniq uniquifies mixed numbers and strings correctly in a tied array'
    );
}
