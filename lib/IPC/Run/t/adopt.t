#!/usr/bin/perl -w

=head1 NAME

adopt.t - Test suite for IPC::Run::adopt

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

use IPC::Run qw( start pump finish ) ;
use UNIVERSAL qw( isa ) ;

##
## $^X is the path to the perl binary.  This is used run all the subprocesses.
##
my @echoer = ( $^X, '-pe', 'BEGIN { $| = 1 }' ) ;

my $h ;
my $in ;
my $out ;
my $fd_map ;

my $h1 ;
my $in1 ;
my $out1 ;
my $fd_map1 ;

sub map_fds() { &IPC::Run::_map_fds }

my @tests = (
##
## harness, pump, run
##
sub {
   $in  = 'SHOULD BE UNCHANGED' ;
   $out = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map = map_fds ;
   $h = start( \@echoer, \$in, \$out ) ;
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
   $in1  = 'SHOULD BE UNCHANGED' ;
   $out1 = 'REPLACE ME' ;
   $? = 99 ;
   $fd_map1 = map_fds ;
   $h1 = start( \@echoer, \$in1, \$out1 ) ;
   ok( isa( $h1, 'IPC::Run' ) ) ;
},
sub { ok( $?, 99 ) },
sub { ok( $in1,  'SHOULD BE UNCHANGED' ) },
sub { ok( $out1, '' ) },
sub { ok( $h1->pumpable ) },


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

sub { warn "hi" ;ok( $h->finish ) },
sub { ok( ! $? ) },
sub { ok( map_fds, $fd_map ) },
sub { ok( $out, "hello\nworld\n" ) },
sub { ok( ! $h->pumpable ) },
) ;

plan tests => scalar @tests ;

skip "adopt not done yet", 1 for ( @tests ) ;
exit 0 ;

$_->() for ( @tests ) ;
