#!/usr/bin/perl -w

=head1 NAME

pump.t - Test suite for IPC::Run::run, etc.

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

use IPC::Run::Debug qw( _map_fds );
use IPC::Run qw( start pump finish timeout ) ;
use UNIVERSAL qw( isa ) ;

##
## $^X is the path to the perl binary.  This is used run all the subprocesses.
##
my @echoer = ( $^X, '-pe', 'BEGIN { $| = 1 }' ) ;

my $in ;
my $out ;

my $h ;

my $fd_map ;

my @tests = (
##
## harness, pump, run
##
sub {
   $in  = 'SHOULD BE UNCHANGED' ;
   $out = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = _map_fds ;
   $h = start( \@echoer, \$in, \$out, timeout 5 ) ;
   ok( isa( $h, 'IPC::Run' ) ) ;
},
sub { ok( $?, 99 ) },

sub { ok( $in,  'SHOULD BE UNCHANGED' ) },
sub { ok( $out, '' ) },
sub { ok( $h->pumpable ) },

sub {
   $in  = '' ;
   $? = 0 ;
   pump_nb $h for ( 1..100 ) ;
   ok( 1 ) ;
},
sub { ok( $in, '' ) },
sub { ok( $out, '' ) },
sub { ok( $h->pumpable ) },

sub {
   $in  = "hello\n" ;
   $? = 0 ;
   pump $h until $out =~ /hello/ ;
   ok( 1 ) ;
},
sub { ok( ! $? ) },
sub { ok( $in, '' ) },
sub { ok( $out, "hello\n" ) },
sub { ok( $h->pumpable ) },

sub {
   $in  = "world\n" ;
   $? = 0 ;
   pump $h until $out =~ /world/ ;
   ok( 1 ) ;
},
sub { ok( ! $? ) },
sub { ok( $in, '' ) },
sub { ok( $out, "hello\nworld\n" ) },
sub { ok( $h->pumpable ) },

## Test \G pos() restoral
sub {
   $in = "hello\n" ;
   $out = "" ;
   $? = 0 ;
   pump $h until $out =~ /hello\n/g ;
   ok( 1 ) ;
},

sub {
   ok pos( $out ), 6, "pos\$out" ;
},

sub {
   $in = "world\n" ;
   $? = 0 ;
   pump $h until $out =~ /\Gworld/gc ;
   ok( 1 ) ;
},


sub { ok( $h->finish ) },
sub { ok( ! $? ) },
sub { ok( _map_fds, $fd_map ) },
sub { ok( $out, "hello\nworld\n" ) },
sub { ok( ! $h->pumpable ) },
) ;

plan tests => scalar @tests ;

$_->() for ( @tests ) ;
