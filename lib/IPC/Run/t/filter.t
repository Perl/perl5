#!/usr/bin/perl -w

=head1 NAME

filter.t - Test suite for IPC::Run filter scaffolding

=cut

BEGIN { 
    if( $ENV{PERL_CORE} ) {
	use Cwd;
        $^X = Cwd::abs_path($^X);
	$^X = qq("$^X") if $^X =~ /\s/;
        chdir '../lib/IPC/Run' if -d '../lib/IPC/Run';
        unshift @INC, 'lib', '../..';
    }
}

use strict ;

use Test ;

use IPC::Run qw( :filters :filter_imp filter_tests ) ;

sub uc_filter {
   my ( $in_ref, $out_ref ) = @_ ;

   return input_avail && do {
      $$out_ref .= uc( $$in_ref ) ;
      $$in_ref = '' ;
      1 ;
   }
}


my $string ;

sub string_source {
   my ( $in_ref, $out_ref ) = @_ ;
   return undef unless defined $string ;
   $$out_ref .= $string ;
   $string = undef ;
   return 1 ;
}


my $accum ;

sub accum {
   my ( $in_ref, $out_ref ) = @_ ;
   return input_avail && do {
      $accum .= $$in_ref ;
      $$in_ref = '' ;
      1 ;
   } ;
}


my $op ;

## "import" the things we're testing.
*_init_filters = \&IPC::Run::_init_filters ;
*_do_filters = \&IPC::Run::_do_filters ;


my @tests = (

filter_tests( "filter_tests", "hello world", "hello world" ),
filter_tests( "filter_tests []",   [qq(hello world)], [qq(hello world)] ),
filter_tests( "filter_tests [] 2", [qw(hello world)], [qw(hello world)] ),

filter_tests( "uc_filter", "hello world", "HELLO WORLD", \&uc_filter ),

filter_tests(
   "chunking_filter by lines 1",
   "hello 1\nhello 2\nhello 3",
   ["hello 1\n", "hello 2\n", "hello 3"],
   new_chunker
),

filter_tests(
   "chunking_filter by lines 2",
   "hello 1\nhello 2\nhello 3",
   ["hello 1\n", "hello 2\n", "hello 3"],
   new_chunker
),

filter_tests(
   "chunking_filter by lines 2",
   [split( /(\s|\n)/, "hello 1\nhello 2\nhello 3" )],
   ["hello 1\n", "hello 2\n", "hello 3"],
   new_chunker
),

filter_tests(
   "chunking_filter by an odd separator",
   "hello world",
   "hello world",
   new_chunker( 'odd separator' )
),

filter_tests(
   "chunking_filter 2",
   "hello world",
   ['hello world' =~ m/(.)/g],
   new_chunker( qr/./ )
),

filter_tests(
   "appending_filter",
   [qw( 1 2 3 )],
   [qw( 1a 2a 3a )],
   new_appender("a")
),
) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;

