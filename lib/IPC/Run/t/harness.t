#!/usr/bin/perl -w

=head1 NAME

harness.t - Test suite for IPC::Run::harness

=cut

BEGIN { 
    if( $ENV{PERL_CORE} ) {
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
	use Cwd;
        $^X = Cwd::abs_path($^X);
	$^X = qq("$^X") if $^X =~ /\s/;
    }
}

use strict ;

use Test ;

use IPC::Run qw( harness ) ;

my $f ;

sub expand_test {
   my ( $args, $expected ) = @_ ;

   my $h ;
   my @out ;
   my $i = 0 ;
   return (
      sub {
	 $h = IPC::Run::harness( @$args ) ;
	 @out = @{$h->{KIDS}->[0]->{OPS}} ;
         ok(
	    scalar( @out ),
	    scalar( @$expected ),
	    join( ' ', @$args )
	 )
      },
      map {
	 my $j = $i++ ;
	 my $h = $_ ;
	 map {
	    my ( $key, $value ) = ( $_, $h->{$_} ) ;
	    sub {
	       my $got = $out[$j]->{$key} ;
	       $got = @$got if ref $got eq 'ARRAY' ;
	       $got = '<undef>' unless defined $got ;
	       ok( $got, $value, join( ' ', @$args ) . ": $j, $key" )
	    } ;
	 } sort keys %$h ;
      } @$expected
   ) ;
}



my @tests = (

   expand_test(
      [ ['a'], qw( <b < c 0<d 0< e 1<f 1< g) ],
      [
	 { TYPE => '<',   SOURCE => 'b', KFD => 0, },
	 { TYPE => '<',   SOURCE => 'c', KFD => 0, },
	 { TYPE => '<',   SOURCE => 'd', KFD => 0, },
	 { TYPE => '<',   SOURCE => 'e', KFD => 0, },
	 { TYPE => '<',   SOURCE => 'f', KFD => 1, },
	 { TYPE => '<',   SOURCE => 'g', KFD => 1, },
      ]
   ),

   expand_test(
      [ ['a'], qw( >b > c 2>d 2> e >>f >> g 2>>h 2>> i) ],
      [
	 { TYPE => '>',   DEST => 'b', KFD => 1, TRUNC => 1, },
	 { TYPE => '>',   DEST => 'c', KFD => 1, TRUNC => 1, },
	 { TYPE => '>',   DEST => 'd', KFD => 2, TRUNC => 1, },
	 { TYPE => '>',   DEST => 'e', KFD => 2, TRUNC => 1, },
	 { TYPE => '>',   DEST => 'f', KFD => 1, TRUNC => '', },
	 { TYPE => '>',   DEST => 'g', KFD => 1, TRUNC => '', },
	 { TYPE => '>',   DEST => 'h', KFD => 2, TRUNC => '', },
	 { TYPE => '>',   DEST => 'i', KFD => 2, TRUNC => '', },
      ]
   ),

   expand_test(
      [ ['a'], qw( >&b >& c &>d &> e ) ],
      [
	 { TYPE => '>', DEST => 'b', KFD => 1, TRUNC => 1, },
	 { TYPE => 'dup', KFD1 => 1, KFD2 => 2 },
	 { TYPE => '>', DEST => 'c', KFD => 1, TRUNC => 1, },
	 { TYPE => 'dup', KFD1 => 1, KFD2 => 2 },
	 { TYPE => '>', DEST => 'd', KFD => 1, TRUNC => 1, },
	 { TYPE => 'dup', KFD1 => 1, KFD2 => 2 },
	 { TYPE => '>', DEST => 'e', KFD => 1, TRUNC => 1, },
	 { TYPE => 'dup', KFD1 => 1, KFD2 => 2 },
      ]
   ),

   expand_test(
      [ ['a'],
         '>&', sub{}, sub{}, \$f,
         '>', sub{}, sub{}, \$f,
         '<', sub{}, sub{}, \$f,
      ],
      [
	 { TYPE => '>',   DEST => \$f, KFD => 1, TRUNC => 1,
	    FILTERS => 2 },
         { TYPE => 'dup', KFD1 => 1,   KFD2 => 2 },
	 { TYPE => '>',   DEST => \$f, KFD => 1, TRUNC => 1,
	    FILTERS => 2 },
	 { TYPE => '<', SOURCE => \$f, KFD => 0,
	    FILTERS => 3 },
      ]
   ),

   expand_test(
      [ ['a'], '<', \$f, '>', \$f ],
      [
	 { TYPE => '<',   SOURCE => \$f, KFD => 0, },
	 { TYPE => '>',   DEST   => \$f, KFD => 1, },
      ]
   ),

   expand_test(
      [ ['a'], '<pipe', \$f, '>pipe', \$f ],
      [
	 { TYPE => '<pipe',   SOURCE => \$f, KFD => 0, },
	 { TYPE => '>pipe',   DEST   => \$f, KFD => 1, },
      ]
   ),

   expand_test(
      [ ['a'], '<pipe', \$f, '>', \$f ],
      [
	 { TYPE => '<pipe',   SOURCE => \$f, KFD => 0, },
	 { TYPE => '>',       DEST   => \$f, KFD => 1, },
      ]
   ),

) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;

