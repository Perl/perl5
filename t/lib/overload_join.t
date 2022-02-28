use v5.36;

BEGIN {
    chdir 't' if -d 't';
    @INC = '../lib';
    require './test.pl';
}

# This class:
# - adds * around non-whitespace "words" when stringified
# - assimilates strings when concatenated (i.e. always return an object)

package BoldStars;

use overload
  '""' => sub {
    return ${ $_[0] } =~ s{(\S+)}{*$1*}gr;
  },
  '.' => sub {
    my ( $left, $right, $swapped ) = @_;
    if ( ref $right eq __PACKAGE__ ) {
        return __PACKAGE__->new( $swapped ? "$$right$$left" : "$$left$$right" );
    }
    else {
        return __PACKAGE__->new( $swapped ? "$right$$left" : "$$left$right" );
    }
  },
  fallback => 1,
  ;

sub new {
    my ( $class, $string ) = @_;
    return bless \$string, $class;
}

package TiedCounter {
  sub TIESCALAR { my $class = shift; bless [''], $class }
  sub FETCH { $_[0][0] .= "-"; return BoldStars->new( $_[0][0] ) }
}


# test script starts here

package main;
use Data::Dumper;
use List::Util qw( reduce );

# test our test class behaves as expected
my $kayo = BoldStars->new('kayo');
my $biff = BoldStars->new('biff');
my $ouch = BoldStars->new('ouch');
my $sock = BoldStars->new('sock');

is( "$kayo",         "*kayo*",        'BoldStars stringification' );
is( $kayo . " zamm", "*kayo* *zamm*", 'BoldStars concatenation' );
is( "zamm " . $kayo, "*zamm* *kayo*", 'BoldStars concatenation (swapped)' );
is( "$kayo + $biff", "*kayo* *+* *biff*", 'BoldStars stringification' );

my $obj = "$kayo ";
is( $obj, '*kayo* ', 'Contatenation with space (right)' );
isa_ok( $obj, 'BoldStars' );

$obj = " $kayo";
is( $obj, ' *kayo*', 'Contatenation with space (left)' );
isa_ok( $obj, 'BoldStars' );

$obj = $kayo . $biff;
is( "$obj", "*kayobiff*", "BoldStars concatenation" );
isa_ok( $obj, 'BoldStars' );

# test that join uses concat overload
{
    my $expected     = BoldStars->new('kayo biff');
    my $expected_str = "$expected";

    my $interpolated = "$kayo $biff";
    is( $interpolated, $expected,     'interpolation (space)' );
    is( $interpolated, $expected_str, 'interpolation str (space)' );
    isa_ok( $interpolated, 'BoldStars' );

    my $reduced = reduce { $a . ' ' . $b } $kayo, $biff;
    is( $reduced, $expected,     'reduce (space)' );
    is( $reduced, $expected_str, 'reduce str (space)' );
    isa_ok( $reduced, 'BoldStars' );

    my $joined = join( ' ', $kayo, $biff );
    is( $joined, $expected,     "join (space)" );
    is( $joined, $expected_str, "join str (space)" );
    isa_ok( $joined, 'BoldStars' );
}

{
    my $expected     = BoldStars->new('kayo + sock');
    my $expected_str = "$expected";

    my $interpolated = "$kayo + $sock";
    is( $interpolated, $expected,     'interpolation (non-space)' );
    is( $interpolated, $expected_str, 'interpolation str (non-space)' );
    isa_ok( $interpolated, 'BoldStars' );

    my $reduced = reduce { $a . ' + ' . $b } $kayo, $sock;
    is( $reduced, $expected,     'reduce (non-space)' );
    is( $reduced, $expected_str, 'reduce str (non-space)' );
    isa_ok( $reduced, 'BoldStars' );

    my $joined = join( ' + ', $kayo, $sock );
    is( $joined, $expected,     "join (non-space)" );
    is( $joined, $expected_str, "join str (non-space)" );
    isa_ok( $joined, 'BoldStars' );

}

# join with a overloaded delim
{
    my $expected     = BoldStars->new('ouch + sock');
    my $expected_str = "$expected";

    my $delim = BoldStars->new(' + ');
    my $interpolated = "ouch${delim}sock";
    is( $interpolated, $expected,     'interpolation (overload-delim)' );
    is( $interpolated, $expected_str, 'interpolation str (overload-delim)' );
    isa_ok( $interpolated, 'BoldStars' );

    my $reduced = reduce { $a . $delim . $b } 'ouch', 'sock';
    is( $reduced, $expected,     'reduce (overload-delim)' );
    is( $reduced, $expected_str, 'reduce str (overload-delim)' );
    isa_ok( $reduced, 'BoldStars' );

    my $joined = join( $delim, 'ouch', 'sock' );
    is( $joined, $expected,     "join (overload-delim)" );
    is( $joined, $expected_str, "join str (overload-delim)" );
    isa_ok( $joined, 'BoldStars' );
}

# join with overloaded delim *and* list values
{
    my $expected     = BoldStars->new('kayo + sock');
    my $expected_str = "$expected";

    my $delim = BoldStars->new(' + ');
    my $interpolated = "$kayo${delim}sock";
    is( $interpolated, $expected,     'interpolation (delim and list)' );
    is( $interpolated, $expected_str, 'interpolation str (delim and list)' );
    isa_ok( $interpolated, 'BoldStars' );

    my $reduced = reduce { $a . $delim . $b } $kayo, 'sock';
    is( $reduced, $expected,     'reduce (delim and list)' );
    is( $reduced, $expected_str, 'reduce str (delim and list)' );
    isa_ok( $reduced, 'BoldStars' );

    my $joined = join( $delim, $kayo, 'sock' );
    is( $joined, $expected,     "join (delim and list)" );
    is( $joined, $expected_str, "join str (delim and list)" );
    isa_ok( $joined, 'BoldStars' );
}

# tied overload as the delim should run FETCH only once
{
    tie my $delim, "TiedCounter";
    my $joined = join( $delim, 'whiz', 'bang', 'biff' );
    is( $joined, "*whiz-bang-biff*", "joined tied" );
}

# tied overload as list item
{
    tie my $dashes, "TiedCounter";
    my $joined = join( '.', 'whiz', $dashes, 'bang' );
    is( $joined, "*whiz.-.bang*", "joined tied in list" );
}

done_testing;

__END__
