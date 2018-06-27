#!./perl

use strict;
use warnings;

use Test::More tests => 30;
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

{
    my $warnings = "";
    local $SIG{__WARN__} = sub { $warnings .= join "", @_ };

    my $cafe = "cafe\x{301}";

    is_deeply( [ uniqstr $cafe ],
               [ $cafe ],
               'uniqstr is happy with Unicode strings' );

    utf8::encode( my $cafebytes = $cafe );

    is_deeply( [ uniqstr $cafe, $cafebytes ],
               [ $cafe, $cafebytes ],
               'uniqstr does not squash bytewise-equal but differently-encoded strings' );

    is( $warnings, "", 'No warnings are printed when handling Unicode strings' );
}

is_deeply( [ uniqnum qw( 1 1.0 1E0 2 3 ) ],
           [ 1, 2, 3 ],
           'uniqnum compares numbers' );

is_deeply( [ uniqnum qw( 1 1.1 1.2 1.3 ) ],
           [ 1, 1.1, 1.2, 1.3 ],
           'uniqnum distinguishes floats' );

SKIP: {
my $vax_float = (pack("d",1) =~ /^[\x80\x10]\x40/);
skip("VAX does not have inf/nan", 1) if $vax_float;

# Hard to know for sure what an Inf is going to be. Lets make one
my $Inf = 0 + eval '1E1000';
my $NaN;
$Inf **= 1000 while ( $NaN = $Inf - $Inf ) == $NaN;

is_deeply( [ uniqnum 0, 1, 12345, $Inf, -$Inf, $NaN, 0, $Inf, $NaN ],
           [ 0, 1, 12345, $Inf, -$Inf, $NaN ],
           'uniqnum preserves the special values of +-Inf and Nan' );
}

{
    my $maxint = ~0;

    is_deeply( [ uniqnum $maxint, $maxint-1, -1 ],
               [ $maxint, $maxint-1, -1 ],
               'uniqnum preserves uniqness of full integer range' );
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

    is_deeply( [ uniqstr @strs ],
               [ $strs[0], $strs[2] ],
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
